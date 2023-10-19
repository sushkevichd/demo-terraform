provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform-dmsu0215"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning so you can see the full revision history of your state files
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform-state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform-state.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-dmsu0215-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-dmsu0215"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-dmsu0215-locks"
    encrypt = true
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform-state.arn
  description = "The ARN of the S3 bucket"
}
output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}