# ---------- Storage: temp audio bucket (auto-expiring) ----------
module "audio_storage" {
  source = "./modules/s3-storage"

  bucket_name           = "${var.project_name}-${data.aws_caller_identity.current.account_id}-text_storage"
  cors_allowed_origins  = ["*"]
  expiration_days       = var.audio_bucket_expiration_days
  tags                  = var.tags
}

# ---------- Function 1: issue a presigned S3 upload URL ----------
module "get_upload_url_function" {
  source = "./modules/lambda-function"

  function_name = "${var.project_name}-get-upload-url"
  source_dir    = "${path.module}/src/get-upload-url"

  bucket_arn  = module.audio_storage.bucket_arn
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  environment_variables = {
    BUCKET_NAME = module.audio_storage.bucket_name
  }

  cors_allow_methods = ["GET"]
  cors_allow_origins = ["*"]
  cors_allow_headers = ["content-type"]
  log_retention_days = var.log_retention_days
  tags               = var.tags
}

# ---------- Function 2: download from S3, call AssemblyAI, return transcript ----------
module "transcribe_function" {
  source = "./modules/lambda-function"

  function_name = "${var.project_name}-transcribe"
  source_dir    = "${path.module}/src/transcribe"

  bucket_arn  = module.audio_storage.bucket_arn
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  environment_variables = {
    BUCKET_NAME          = module.audio_storage.bucket_name
    ASSEMBLYAI_API_KEY   = var.assemblyai_api_key
  }

  cors_allow_methods = ["POST"]
  cors_allow_origins = ["*"]
  cors_allow_headers = ["content-type"]
  log_retention_days = var.log_retention_days
  tags               = var.tags
}

# ---------- Frontend: static site bucket, index.html templated with both Function URLs ----------
module "frontend" {
  source = "./modules/static-frontend"

  bucket_name          = "${var.project_name}-site-${data.aws_caller_identity.current.account_id}"
  index_template_path  = "${path.module}/frontend/index.html.tftpl"

  get_upload_url_endpoint = module.get_upload_url_function.function_url
  transcribe_endpoint     = module.transcribe_function.function_url

  tags = var.tags
}
