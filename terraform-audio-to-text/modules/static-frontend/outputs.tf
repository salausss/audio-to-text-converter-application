output "website_endpoint" {
  description = "S3 static website endpoint URL (HTTP only)"
  value       = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "bucket_name" {
  description = "Name of the frontend bucket"
  value       = aws_s3_bucket.site.id
}
