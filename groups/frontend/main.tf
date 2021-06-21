provider "aws" {
  region  = var.region
  version = "~> 2.65.0"
}

terraform {
  backend "s3" {
  }
}

data "aws_caller_identity" "current" {}
