output "function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_url" {
  description = "Public HTTPS Function URL"
  value       = aws_lambda_function_url.this.function_url
}
