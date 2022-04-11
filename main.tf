##########################################################################################
##
## create infra for a new static website hosting
##
## - [AWS] create the new zone in route53
## - [AWS] gather the NS from this new route53 zone
## - [GANDI] create these NS records in gandi
## - [AWS] create the TLS certificate in ACM
## - [AWS] create the S3 bucket
## - [AWS] create the iam credentials for github action to deploy files?
## - [AWS] create the cloudfront distribution
## - [AWS] create the OIA
##
## inspired from https://gist.github.com/danihodovic/a51eb0d9d4b29649c2d094f4251827dd
## 
##########################################################################################

# Declare gandi (dns) and aws providers
terraform {
  required_providers {
    gandi = {
      version = "~> 2.0.0"
      source  = "go-gandi/gandi"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9"
    }
  }
}

provider "gandi" {
  key = var.GANDI_API_KEY
}

provider "aws" {
  region = "${var.AWS_REGION}"
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

locals {
  s3_website_endpoints = [
      module.test-djoo-org.bucket_regional_domain_name,
      module.test2-djoo-org.bucket_regional_domain_name,
    ]
  route53_domain = [
    module.test-djoo-org.route53_domain,
    module.test2-djoo-org.route53_domain,
  ]
  cdn_domain = [
    module.test-djoo-org.cdn_domain,
    module.test2-djoo-org.cdn_domain,
  ]
}

module "test-djoo-org" {
  source = "./modules/terraform-djoo-static-website-aws-gandi"
  GANDI_API_KEY = var.GANDI_API_KEY
  AWS_REGION = var.AWS_REGION
  DOMAIN_NAME = var.DOMAIN_NAME
  SUB_DOMAIN_NAME = "test"
  S3_BUCKET_FORCE_DESTROY = var.S3_BUCKET_FORCE_DESTROY
}

module "test2-djoo-org" {
  source = "./modules/terraform-djoo-static-website-aws-gandi"
  GANDI_API_KEY = var.GANDI_API_KEY
  AWS_REGION = var.AWS_REGION
  DOMAIN_NAME = var.DOMAIN_NAME
  SUB_DOMAIN_NAME = "test2"
  S3_BUCKET_FORCE_DESTROY = var.S3_BUCKET_FORCE_DESTROY
}

# module "test9-djoo-org" {
#   source = "./modules/terraform-djoo-static-website-aws-gandi"
#   GANDI_API_KEY = var.GANDI_API_KEY
#   AWS_REGION = var.AWS_REGION
#   DOMAIN_NAME = var.DOMAIN_NAME
#   SUB_DOMAIN_NAME = "test9"
#   S3_BUCKET_FORCE_DESTROY = var.S3_BUCKET_FORCE_DESTROY
# }
