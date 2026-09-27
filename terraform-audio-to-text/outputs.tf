output "get_upload_url_endpoint" {
  description = "Function URL for requesting a presigned upload URL"
  value       = module.get_upload_url_function.function_url
}

output "transcribe_endpoint" {
  description = "Function URL for triggering transcription"
  value       = module.transcribe_function.function_url
}

output "audio_bucket_name" {
  description = "Temp audio storage bucket"
  value       = module.audio_storage.bucket_name
}

output "website_url" {
  description = "S3 static website URL — open this in a browser"
  value       = "http://${module.frontend.website_endpoint}"
}

output "frontend_bucket_name" {
  description = "Static frontend bucket"
  value       = module.frontend.bucket_name
}
