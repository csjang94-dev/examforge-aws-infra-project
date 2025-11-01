output "bucket_id" {
  value = aws_s3_bucket.site.id
}

output "bucket_arn" {
  value = aws_s3_bucket.site.arn
}

output "website_endpoint" {
  description = "The S3 bucket website endpoint"
  value       = aws_s3_bucket_website_configuration.site_website.website_endpoint
}