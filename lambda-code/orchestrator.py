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
SNOWFLAKE_SECRET_MANAGER_NAME = os.environ["SNOWFLAKE_SECRET_MANAGER_NAME"]
API_KEYS_SECRET_MANAGER_NAME = os.environ["API_KEYS_SECRET_MANAGER_NAME"]
STREAM_NAME = os.environ["FIREHOSE_STREAM_NAME"]
ECS_CLUSTER_NAME = os.environ['ECS_CLUSTER_NAME']
ECS_TASK_DEFINITION_ARN = os.environ['ECS_TASK_DEFINITION_ARN']
ECS_SECURITY_GROUP_ID = os.environ["ECS_SECURITY_GROUP_ID"]
ECS_TASK_SUBNET_ID = os.environ["ECS_TASK_SUBNET_ID"]
CONTAINER_NAME = os.environ["CONTAINER_NAME"]


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
    offset = 0
    google_maps_api_calls = 0
    total_records_sent = 0
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

                    google_maps_api_calls += 1
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

    return google_maps_api_calls


def spin_up_dbt_container(snowflake_credentials):
    """
    Spins up an ECS task to run a dbt container.

    Args:
        snowflake_credentials (dict): Snowflake credentials.
    """
    # Create an ECS client
    ecs_client = boto3.client('ecs')

    # Extract ecs_task_definition_name from ecs_task_definition_arn using a regular expression
    match = re.search(r'task-definition/(.+):(\d+)', ECS_TASK_DEFINITION_ARN)
    ecs_task_definition_name = match.group(1) + ':' + match.group(2)

    logger.info("Setting container environment variables")

    # Set the container overrides
    container_overrides = [
        {
            'name': CONTAINER_NAME,
            'environment': [
                {'name': 'SNF_ACCOUNT', 'value': snowflake_credentials['account']},
                {'name': 'SNF_USER', 'value': snowflake_credentials['user']},
                {'name': 'SNF_ROLE', 'value': snowflake_credentials['role']},
                {'name': 'SNF_PASSWORD', 'value': snowflake_credentials['password']},
                {'name': 'SNF_WAREHOUSE', 'value': snowflake_credentials['warehouse']},
                {'name': 'SNF_DATABASE', 'value': snowflake_credentials['database']},
                {'name': 'SNF_SCHEMA', 'value': snowflake_credentials['schema']},
                {'name': 'DBT_ENV', 'value': os.getenv('ENVIRONMENT')}
            ]
        },
    ]

    logger.info("Submitting task to ECS")

    response = ecs_client.run_task(
        taskDefinition=ecs_task_definition_name,
        cluster=ECS_CLUSTER_NAME,
        launchType='FARGATE',
        overrides={'containerOverrides': container_overrides},
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': [ECS_TASK_SUBNET_ID],
                'securityGroups': [ECS_SECURITY_GROUP_ID],
                'assignPublicIp': 'ENABLED'
            }
        }
    )
    logger.info(f"Task successfully submitted to ECS. Task arn: {response['tasks'][0]['taskArn']}")


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
        google_maps_api_calls = get_data_from_socrata_and_send_to_s3(api_keys)

        logger.info("SF incident data successfully ingested into S3")
        logger.info(f"Total amount of API calls to google maps: {google_maps_api_calls}")

        # Sleep for 60 seconds to wait for the last KDF batch to arrive in Snowflake
        #time.sleep(60)

        # Retrieve Snowflake credentials and spin up dbt container
        #snowflake_credentials = retrieve_sensitive_data(SNOWFLAKE_SECRET_MANAGER_NAME)
        #spin_up_dbt_container(snowflake_credentials)

    except Exception as error:
        logger.error(traceback.format_exc())
