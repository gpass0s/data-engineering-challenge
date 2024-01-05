CREATE OR REPLACE
STORAGE INTEGRATION S3_role_integration TYPE = EXTERNAL_STAGE STORAGE_PROVIDER = S3 ENABLED = TRUE STORAGE_AWS_ROLE_ARN = "arn:aws:iam::777455183230:role/service-role/data-engineering-challenge-dev-s3AccessRoleForSnowflake" STORAGE_ALLOWED_LOCATIONS = ("s3://data-engineering-challenge-dev-sf-fire-incident/");


CREATE OR REPLACE TABLE S3_landing_table(ingestion_time timestamp, content variant, s3_path_location string)
CREATE OR REPLACE FILE format public.json_format TYPE = JSON
CREATE OR REPLACE stage S3_stage url = ('s3://data-engineering-challenge-dev-sf-fire-incident/') storage_integration = S3_role_integration file_format =public.json_format;


CREATE OR REPLACE pipe data_engineering_challenge.public.S3_pipe auto_ingest=TRUE AS COPY INTO data_engineering_challenge.public.S3_landing_table
FROM
  (SELECT sysdate() AS ingestion_time,
          $1::variant AS content,
          metadata$filename AS s3_path_location
   FROM @data_engineering_challenge.public.S3_stage) file_format = public.json_format