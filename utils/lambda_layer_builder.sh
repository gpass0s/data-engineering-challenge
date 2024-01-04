#!/bin/bash

echo "Executing build.sh..."

if [[ $root_directory ]]; then # if the root_directory is set
  cd $root_directory
fi

if [[ -z $package_output_name ]]; then # if package_output_name is not set
  package_output_name=lambda-layer
fi

if [[ -z $function_name ]]; then # if function_name is not set
  function_name=layer
fi

if [[ -z $runtime ]]; then # if runtime is not set
  runtime=python3.9
fi

if [[ -z $requirements_path ]]; then # if requirements_path is not set
  requirements_path=requirements.txt
fi

mkdir $package_output_name

# Create and activate virtual environment...
virtualenv -p $runtime env_$function_name
source env_$function_name/bin/activate

# Installing python dependencies...
FILE=$requirements_path

if [ -f "$FILE" ]; then
  echo "Installing dependencies..."
  echo "From: requirement.txt file exists..."
  pip install -r "$FILE"

else
  echo "Error: requirement.txt does not exist!"
fi

# Deactivate virtual environment...
deactivate

cd $package_output_name
mkdir python
cd python
mkdir lib
cd lib
mkdir $runtime
cd $runtime
mkdir site-packages
cd ../../../../

# Create deployment package...
echo "Creating deployment package..."

cp -r env_$function_name/lib/$runtime/site-packages/. $package_output_name/python/lib/$runtime/site-packages/
cp -r lambdas/dependencies $package_output_name/python/lib/$runtime/site-packages/

# Removing virtual environment folder...
echo "Removing virtual environment folder..."
rm -rf env_$function_name

# Zipping deployment package...
echo "Zipping deployment package..."
cd $package_output_name
zip -r ../utils/lambda-deployment-packages/$package_output_name.zip .

# Installing psycopg2 into aws-lambda
# https://www.timescale.com/blog/aws-lambda-for-beginners-overcoming-the-most-common-challenges/
# wget https://github.com/jkehler/awslambda-psycopg2/archive/refs/heads/master.zip
# unzip master.zip
# mkdir -p python/psycopg2/
# cp -r awslambda-psycopg2-master/psycopg2-3.9/* python/psycopg2/
# zip -ur ../utils/lambda-deployment-packages/$package_output_name.zip python/

# Removing deployment package folder
echo "Removing deployment package folder..."
cd ../
rm -rf $package_output_name
echo "Finished script execution!"