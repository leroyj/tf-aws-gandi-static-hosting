##
# OUTPUT
##

output "bucket_regional_domain_name" {
  description = "S3 Website endpoint"
  value = "${aws_s3_bucket.site.bucket_regional_domain_name}"
}

output "route53_domain" {
  description = "Route53 domain"
  value = "${aws_route53_record.root_domain.fqdn}"
}

output "cdn_domain" {
  description = "CDN domain"
  value = "${aws_cloudfront_distribution.cdn.domain_name}"
}
