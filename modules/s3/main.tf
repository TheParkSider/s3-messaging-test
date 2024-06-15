resource "aws_s3_bucket" "this" {
  bucket        = "${local.prefix}-event-sender-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id

  topic {
    id        = "${local.prefix}-event-sender-notification"
    topic_arn = var.topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}