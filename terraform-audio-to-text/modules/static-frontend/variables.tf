variable "bucket_name" {
  description = "Name of the S3 bucket for the static frontend site"
  type        = string
}

variable "index_template_path" {
  description = "Path to the index.html.tftpl template file"
  type        = string
}

variable "get_upload_url_endpoint" {
  description = "Function URL of the get-upload-url Lambda, injected into the page"
  type        = string
}

variable "transcribe_endpoint" {
  description = "Function URL of the transcribe Lambda, injected into the page"
  type        = string
}

variable "tags" {
  description = "Tags applied to the bucket"
  type        = map(string)
  default     = {}
}
