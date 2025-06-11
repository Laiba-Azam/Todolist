terraform {
  backend "s3" {
    bucket         = "terraform-backend-me"  # Create this bucket first
    key            = "todolist/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


# Your existing website resources
resource "random_id" "unique" {
  byte_length = 4
}

resource "aws_s3_bucket" "site" {
  bucket = "todolist-${random_id.unique.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
  error_document { key = "error.html" }
}

resource "aws_s3_bucket_public_access_block" "disable_bpa" {
  bucket = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.site.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.disable_bpa]
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}
