# Lets the S3 service, acting on behalf of the frontend site bucket, invoke
# these two Lambda functions. source_arn scopes it so only this specific
# bucket can trigger them — not any bucket in the account.

resource "aws_lambda_permission" "site_bucket_invoke_get_upload_url" {
  statement_id  = "AllowInvokeFromSiteBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.get_upload_url_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.frontend.bucket_arn
}

resource "aws_lambda_permission" "site_bucket_invoke_transcribe" {
  statement_id  = "AllowInvokeFromSiteBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.transcribe_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.frontend.bucket_arn
}