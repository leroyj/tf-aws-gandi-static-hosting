output "s3_website_endpoint" {
    description = "S3 Website endpoint"
  value = local.s3_website_endpoints
}

output "route53_domain" {
  description = "Route53 domain"
  value = local.route53_domain
}

output "cdn_domain" {
  description = "CDN domain"
  value = local.cdn_domain
}
