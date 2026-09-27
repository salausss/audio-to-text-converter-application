resource "aws_s3_bucket" "site" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }
}

# The site must be publicly readable to serve as a plain static website.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Renders index.html from a template, injecting the two Lambda Function
# URLs so nothing is hardcoded — a redeploy that changes either URL
# automatically re-uploads the page with the new value.
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  content_type = "text/html"

  content = templatefile(var.index_template_path, {
    get_upload_url_endpoint = var.get_upload_url_endpoint
    transcribe_endpoint     = var.transcribe_endpoint
  })

  etag = md5(templatefile(var.index_template_path, {
    get_upload_url_endpoint = var.get_upload_url_endpoint
    transcribe_endpoint     = var.transcribe_endpoint
  }))
}
