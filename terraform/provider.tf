terraform {
  backend "s3" {
    # Replace with your S3 bucket name
    bucket         = "frp-yamachu-dev-terraform"
    key            = "terraform/state.tfstate"
    region         = "ap-northeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
