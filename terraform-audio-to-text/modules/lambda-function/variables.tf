variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_dir" {
  description = "Path to the Lambda source directory (containing index.mjs, package.json, node_modules)"
  type        = string
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "architecture" {
  description = "Lambda architecture (arm64 is cheaper than x86_64)"
  type        = string
  default     = "arm64"
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 300
}

variable "environment_variables" {
  description = "Environment variables to inject into the function"
  type        = map(string)
  default     = {}
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket this function needs CRUD access to"
  type        = string
}

variable "cors_allow_methods" {
  description = "HTTP methods allowed on this function's Function URL CORS config"
  type        = list(string)
  default     = ["GET"]
}

variable "cors_allow_origins" {
  description = "Origins allowed on this function's Function URL CORS config"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allow_headers" {
  description = "Headers allowed on this function's Function URL CORS config"
  type        = list(string)
  default     = ["content-type"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (keeps log storage cost near zero)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to the function"
  type        = map(string)
  default     = {}
}
