terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  shared_credentials_files = ["C:/Users/Matias/.aws/credentials"] # default
  profile = "default" # you may change to desired profile
}


terraform {
  backend "s3" {
    bucket = "deploy-api-restaurant"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
