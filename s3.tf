resource "aws_s3_bucket" "tfstate" {
  bucket = "mohit-terraform-state-bucket-l2" # Change this to the same unique bucket name used in providers.tf

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
} 