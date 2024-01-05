terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key     = "data-engineering-challenge/terraform.tfstate"
    encrypt = true
    region  = "us-east-1"
  }

}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}