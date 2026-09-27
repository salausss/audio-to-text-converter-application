variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short name used as a prefix for resource naming"
  type        = string
  default     = "audio-to-text"
}

variable "assemblyai_api_key" {
  description = "API key for AssemblyAI transcription (from assemblyai.com dashboard)"
  type        = string
  sensitive   = true
}

variable "audio_bucket_expiration_days" {
  description = "Days after which uploaded audio is auto-deleted from the temp bucket"
  type        = number
  default     = 1
}

variable "lambda_memory_size" {
  description = "Memory (MB) for both Lambda functions"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout (seconds) for both Lambda functions"
  type        = number
  default     = 300
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project = "audio-to-text"
  }
}
