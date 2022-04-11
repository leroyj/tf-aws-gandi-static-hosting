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

locals {
  FQDN = "${var.SUB_DOMAIN_NAME}.${var.DOMAIN_NAME}"
  s3_origin_id = "myS3Origin"
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

###
# CREATE AWS BUCKET
# Note: The bucket name needs to carry the same name as the domain!
# http://stackoverflow.com/a/5048129/2966951
###

resource "aws_s3_bucket" "site" {
  bucket = "${local.FQDN}"
  tags = {
    Name = "${local.FQDN}"
  }
  force_destroy = var.S3_BUCKET_FORCE_DESTROY
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront_OAI" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront_OAI.json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront_OAI" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.site.iam_arn]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.site.arn}/*",
    ]
  }
}

###
# CREATE SUB_DOMAIN_NAME ZONE IN ROUTE53
# Note: Creating this route53 zone is not enough. The domain's name servers need to point to the NS
# servers of the route53 zone. Otherwise the DNS lookup will fail.
# To verify that the dns lookup succeeds: `dig site @nameserver`
resource "aws_route53_zone" "main" {
  name = "${local.FQDN}"
}

###
# CREATE THE NS RECORDS (DEFINED BY ROUTE53) OF THE SUB_DOMAIN_NAME ZONE IN GANDI
###
resource "gandi_livedns_record" "site" {
  zone   = "${var.DOMAIN_NAME}"
  name   = "${var.SUB_DOMAIN_NAME}"
  type   = "NS"
  ttl    = 3600
  values = [
    for item in aws_route53_zone.main.name_servers:
      replace(item,"/$/",".")
  ]
}

###
# CREATE THE A RECORDS OF OUR WEBSITE
#   "SUB_DOMAIN_NAME.DOMAIN_NAME" and
#   "www.SUB_DOMAIN_NAME.DOMAIN_NAME"
# AND POINT THEM TO THE CLOUDFRONT DISTRIBUTION
###
resource "aws_route53_record" "root_domain" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "${local.FQDN}"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.cdn.domain_name}"
    zone_id = "${aws_cloudfront_distribution.cdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

###
# CREATE THE ACM CERTIFICATE
# CREATE THE DNS VALIDATION RECORD
# VALIDATE THE CERTIFICATE
###
resource "aws_acm_certificate" "cert" {
  domain_name = "${local.FQDN}"
  validation_method = "DNS"
  subject_alternative_names = [
#    "www.${local.FQDN}"
  ]
  provider = aws.virginia
}

resource "aws_route53_record" "verif-records" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}
# TODO CREATE www.SUBDOMAIN_NAME.DOMAIN_NAME validation record

resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.verif-records : record.fqdn]
  timeouts {
    create = "10m"
  }
  provider = aws.virginia
}

###
# CREATE THE CLOUDFRONT DISTRIBUTION
###
resource "aws_cloudfront_distribution" "cdn" {
  # If using route53 aliases for DNS we need to declare it here too, otherwise we'll get 403s.
  # aliases = ["${local.FQDN}, www.${local.FQDN}"]
  aliases = ["${local.FQDN}"]

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # The cheapest priceclass
  price_class = "PriceClass_100"

  # This is required to be specified even if it's not used.
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method = "sni-only"
    #cloudfront_default_certificate = true
  }
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "${local.s3_origin_id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.site.cloudfront_access_identity_path
    }
  }
}

##
# ORIGIN ACCESS IDENTITY
##
resource "aws_cloudfront_origin_access_identity" "site" {
  comment = "${local.FQDN}"
}
