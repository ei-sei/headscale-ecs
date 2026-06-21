terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
