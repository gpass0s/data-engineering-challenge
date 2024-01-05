#!/usr/bin/python3.9
# -*- encoding: utf-8 -*-
"""
Created on Wed Jan 3 9:31pm BRT 2024
author: https://github.com/gpass0s/
This module implements an orchestrator that fetches São Francisco Fire Incident
from Socrata API and spins up an ECS task to run a dbt container
"""

import boto3
import logging
import traceback
import requests
import os
import re
import json
import time

from requests.auth import HTTPBasicAuth

# Configure logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Environment variables
API_KEYS_SECRET_MANAGER_NAME = os.environ["API_KEYS_SECRET_MANAGER_NAME"]
STREAM_NAME = os.environ["FIREHOSE_STREAM_NAME"]


def retrieve_sensitive_data(secret_manager_name):
    """
    Retrieves sensitive information from AWS secret manager.

    Args:
        secret_manager_name (str): Name of the secret manager.

    Returns:
        dict: Sensitive data retrieved from the secret manager.
    """
    session = boto3.session.Session()
    client = session.client(
        service_name="secretsmanager",
        region_name="us-east-1"
    )

    sensitive_data = {}
    logger.info(f"Retrieving credentials from secret {secret_manager_name}")
    response = client.get_secret_value(SecretId=secret_manager_name)
    secret = response["SecretString"]
    sensitive_data.update(json.loads(secret))

    return sensitive_data


def fetch_coordinates_from_google_maps(st_address, zip_code, api_keys):
    """
    Retrieves geo-coordinates from Google Maps API.

    Args:
        st_address (str): street address
        zip_code (int): zip code
        api_keys (dict): API keys for authentication.

    Returns:
        dict: Geo-coordinates.
    """

    url = "https://maps.googleapis.com/maps/api/geocode/json"
    address = f"{st_address}, San Francisco, CA, {zip_code}"
    payload = {"address": address, 'key': api_keys['GoogleMapsAPIKey']}

    resp = requests.get(url, params=payload)
    if resp.status_code != 200:
        logger.info(f"Google API status_code: {resp.status_code}")
        logger.info(f"Google API response: {resp.text}")
        return {"lng": 0, "lat": 0}
    data = json.loads(resp.text)

    return data['results'][0]['geometry']['location']


def get_data_from_socrata_and_send_to_s3(api_keys):
    """
    Retrieves data from Socrata API and sends it to Amazon Kinesis Firehose.

    Args:
        api_keys (dict): API keys for authentication.
    """
    logger.info("Requesting SF fire incident information from Socrata")
    auth = HTTPBasicAuth(api_keys['KeyId'], api_keys['KeySecret'])

    firehose_client = boto3.client('firehose')

    url = "https://data.sfgov.org/resource/wr8u-xric.json?"
    offset, total_records_sent = 0, 0
    while True:
        response = requests.get(
            url=f"{url}$limit=50000&$offset={offset}&$order=incident_number",
            auth=auth
        )
        logger.info(f"Socrata API response code: {response.status_code}")
        records = json.loads(response.text)
        logger.info(f"Records count retrieved from Socrata API: {len(records)}")
        # Break in case no records are fetched
        if not records:
            logger.info(f"Socrata API response: {response.text}")
            break

        payload = []
        for record in records:
            # Move latitude and longitude data to the top level of the
            # JSON structure for easier access
            try:
                record['lng'] = record['point']['coordinates'][0]
                record['lat'] = record['point']['coordinates'][1]
            except KeyError as error:
                # If the record lacks coordinate information, retrieve it
                # from Google Maps using the address and zipcode.
                logger.info(f"Record with no coordinates: {record}")

                try:
                    coordinates = fetch_coordinates_from_google_maps(
                        record['address'],
                        record['zipcode'],
                        api_keys
                    )
                    record['lng'] = coordinates['lng']
                    record['lat'] = coordinates['lat']

                except KeyError as error:
                    record['lng'] = -122.3965
                    record['lat'] = 37.7937

            payload.append(dict(Data=json.dumps(record)))

            # Each PutRecordBatch request supports up to 500 records.
            if len(payload) % 500 == 0:
                firehose_client.put_record_batch(
                    DeliveryStreamName=STREAM_NAME,
                    Records=payload
                )
                total_records_sent += len(payload)
                logger.info(f"Total records sent to Firehose: {total_records_sent}")
                payload = []

        if payload:
            firehose_client.put_record_batch(
                DeliveryStreamName=STREAM_NAME,
                Records=payload
            )
            total_records_sent += len(payload)
            logger.info(f"Total records sent to Firehose: {total_records_sent}")

        offset += len(records)


def lambda_handler(event, context):
    """
    Lambda function handler.

    Args:
        event: Lambda event input.
        context: Lambda context.

    Returns:
        None
    """
    try:
        # Retrieve Socrata API keys and send data to Firehose
        api_keys = retrieve_sensitive_data(API_KEYS_SECRET_MANAGER_NAME)
        get_data_from_socrata_and_send_to_s3(api_keys)

        logger.info("SF incident data successfully ingested into S3")
    except Exception as error:
        logger.error(traceback.format_exc())
