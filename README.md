# data-engineering-challenge
![Terraform](https://img.shields.io/badge/Terraform-7B42BC.svg?style=for-the-badge&logo=Terraform&logoColor=white)
![AWS](https://img.shields.io/badge/Amazon%20AWS-232F3E.svg?style=for-the-badge&logo=Amazon-AWS&logoColor=white)
![S3](https://img.shields.io/badge/Amazon%20S3-569A31.svg?style=for-the-badge&logo=Amazon-S3&logoColor=white)

## 1. Introduction
This project serves to demonstrate proficiency in Data Engineering, problem-solving abilities, 
and knowledge in Software development. The challenge involves making 
the massive data set of fire incidents in San Francisco, United States, available 
in a data warehouse for analysis and visualization. The dataset, hosted by 
[Socrata](https://dev.socrata.com/), comprises approximately 650k rows and 64 columns. 
Detailed information about the dataset can be found 
[here](https://data.sfgov.org/Public-Safety/Fire-Incidents/wr8u-xric/about_data).

### 1.1 Project Overview
The project's cloud infrastructure is entirely coded using Terraform, located in 
the `infra-as-code` folder. Additionally, it integrates with a dbt project under 
the `data_engineering_challenge` folder, allowing analytics to organize and run their 
SQL scripts on Snowflake seamlessly. The project utilizes Pipenv as its Python 
virtualenv management tool.

### 1.2 Solution Implemented
Given the large size of the fire incidents dataset, handling, 
transforming, and storing it becomes a real-world data engineering 
challenge. Luckily, Socrata provides a comprehensive API for 
fetching data programmatically using pagination and query statements. 
The chosen solution involves several stages outlined below.
<p align="center">
  <img src="utils/data-engineering-challenge.png">
  <br/>
</p>

Let us go through each stage of the data journey, one piece at a time in order to clarify what is 
happening on the image above.

### 1.2.1 Pulling Information from Socrata API
A Python code snippet deployed within a Lambda function fetches data from Socrata using 
AWS Secret Manager to retrieve API keys. This code retrieves 50,000 dataset records per request, 
transforms geo-coordinate points within the JSON structure, and fetches missing points from 
the Google Maps API using street addresses. The Lambda then aggregates batches of 
500 records and sends them to Kinesis Data Firehose using the `put_record_batch` method from the 
Firehose SDK API.

### 1.2.2 Aggregation and Dynamic Partitioning
Firehose buffers records for 30 seconds or until 10MB chunks are reached. 
It dynamically partitions records by incident date and delivers them to S3.
Check the image below to observe the partitioning of records in S3 facilitated by Firehose.

### 1.2.3 Ingesting Data into Snowflake
Snowflake is chosen as the data warehouse due to its high availability, seamless data sharing, 
impressive performance, and the absence of any manual maintenance requirements. 
To seamlessly ingest data from S3 into Snowflake, the Snowpipe mechanism is employed. 
Snowpipe enables loading data from files as soon as they’re available in a stage, ensuring data 
availability in micro-batches. Snowpipe makes the data available to users within minutes, 
rather than manually executing COPY statements on a schedule to load larger batches. 
[This](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3) document explain 
step by step how snowpipe is configured. Within the context of this project, 
[this](https://github.com/gpass0s/data-engineering-challenge/blob/main/utils/snowpipe_creation.sql) file 
contains the commands utilized for setting up Snowpipe, 
facilitating the ingestion of San Francisco fire incident data into Snowflake

### 1.2.4 Data Enhancement using dbt
A dbt project is integrated to flatten incoming JSON files from Snowpipe. 
This project, located in the `data_engineering_challenge` folder, includes a dbt 
model that flattens the JSON files and builds an incremental table within Snowflake, 
containing all 650k records and 64 columns from the SF fire incidents dataset. 
The dbt project is automatically deployed to AWS using a CI/CD pipeline.

### 1.2.5 Data Visualization
Metabase, an open-source visualization tool, is chosen for 
creating dashboards and exploring the SF fire incident data. For this challenge, 
Metabase Cloud is used to make the analysis public with minimal maintenance. 
Access the dashboards and visualizations [here](link for the dashboards).

### 1.3 Project Tree Directory Structure
```css
├── data_engineering_challenge
│   ├── analyses
│   ├── dbt_packages
│   ├── dbt_project.yml
│   ├── macros
│   ├── models
│   │   ├── san_francisco_fire_incidents.sql
│   │   └── sources.yml
│   ├── README.md
│   ├── seeds
│   ├── snapshots
│   └── tests
├── lambda-code
│   └── orchestrator.py
├── Pipfile
├── Pipfile.lock
├── README.md
├── requirements.txt
├── utils
│   ├── lambda-deployment-packages
│   │   └── lambda-layer.zip
│   ├── lambda_layer_builder.sh
│   └── snowpipe_creation.sql
│
└── infra-as-code
    ├── backend.tf
    ├── dbt.compute.engine.settings.tf
    ├── main.tf
    ├── modules
    │   ├── ecr
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── ecs-cluster
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   ├── ecs-task-definition
    │   │   ├── logging
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   └── variables.tf
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── permissions
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   └── variables.tf
    │   │   └── variables.tf
    │   ├── kinesis-data-firehose
    │   │   ├── main.tf
    │   │   ├── observability
    │   │   │   ├── main.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── outputs.tf
    │   │   ├── permissions
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   ├── lambda
    │   │   ├── cloudwatch-trigger
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── invoker
    │   │   │   ├── main.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── main.tf
    │   │   ├── observability
    │   │   │   ├── main.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── outputs.tf
    │   │   ├── package
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── permissions
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   ├── lambda-layer
    │   │   ├── build
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   ├── variables.tf
    │   │   │   └── versions.tf
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   ├── permissions
    │   │   └── s3-access-role-for-snowflake
    │   │       ├── main.tf
    │   │       ├── outputs.tf
    │   │       ├── variables.tf
    │   │       └── versions.tf
    │   ├── s3
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   └── vpc-resources
    │       ├── elastic-ip
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   └── variables.tf
    │       ├── internet-gateway
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   └── variables.tf
    │       ├── nat-gateway
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   └── variables.tf
    │       ├── route-table
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   └── variables.tf
    │       ├── security-group
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   └── variables.tf
    │       ├── subnet
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   └── variables.tf
    │       └── vpc
    │           ├── main.tf
    │           ├── outputs.tf
    │           └── variables.tf
    ├── s3.bucket.settings.tf
    ├── variables.default.tf
    └── vpc.settings.tf
```

## 3. Github Actions Workflows for dbt and Terraform Deployment
This repository employs GitHub Actions workflows to automate the deployment of both the 
Terraform infrastructure and dbt project on AWS. The workflow, outlined in this
YAML file, orchestrates the seamless execution of deployment processes.

### 3.1 dbt project deployment workflow