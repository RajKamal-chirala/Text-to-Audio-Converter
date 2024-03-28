output "wesite_url" {
  description = "Website url"
  value       = aws_s3_bucket_website_configuration.web-config.website_endpoint
}