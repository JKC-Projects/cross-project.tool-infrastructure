terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8"
    }
  }

  # set TF CLI version
  required_version = "~> 1.1"

  # use Terraform Cloud as state backend
  cloud {
    organization = "jkc-projects"
    workspaces {
      tags = ["tool-infrastructure"]
    }
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      project     = "cross-project"
      managed_by  = "terraform"
      github_repo = "cross-project.tool-infrastructure"
    }
  }
}

# Data block allows us to access the above default tags
# https://learn.hashicorp.com/tutorials/terraform/aws-default-tags?in=terraform/aws
data "aws_default_tags" "current" {}

# Get information about the AWS account using this terraform
data "aws_caller_identity" "current" {}