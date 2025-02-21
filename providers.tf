terraform {
  required_providers {
    aws = {
      version = "5.87.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "example"

  default_tags {
    tags = {
        Purpose = "Demo"
    }
  }
}
