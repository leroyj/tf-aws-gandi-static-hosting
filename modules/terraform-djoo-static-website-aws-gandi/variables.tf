## GANDI
variable "GANDI_API_KEY" {
  description = "Gandi API key"
  type        = string
  sensitive   = true
}

## AWS
variable "AWS_REGION" {
  description = "AWS region"
  type = string
  default     = "eu-west-3"
}

## COMMON
variable "DOMAIN_NAME" {
  description = "Domain name"
  type = string
  default = "djoo.org"
}

variable "SUB_DOMAIN_NAME" {
  description = "Sub domain name"
  type = string
  default = "test"
}

variable "S3_BUCKET_FORCE_DESTROY" {
  description = "Force destroy S3 bucket"
  default = false
}
