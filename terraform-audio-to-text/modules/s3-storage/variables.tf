variable "bucket_name" {
  description = "Name of the S3 bucket used for temporary audio storage"
  type        = string
}

variable "cors_allowed_origins" {
  description = "Allowed origins for S3 CORS (PUT upload from browser)"
  type        = list(string)
  default     = ["*"]
}

variable "expiration_days" {
  description = "Days after which uploaded audio objects are auto-deleted"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to the bucket"
  type        = map(string)
  default     = {}
}
