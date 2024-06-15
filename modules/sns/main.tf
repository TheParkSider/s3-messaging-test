data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:${local.prefix}-event-sender-topic"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.msg_src.arn]
    }
  }
}

resource "aws_sns_topic" "this" {
  name = "${local.prefix}-event-sender-topic"
  policy = data.aws_iam_policy_document.this.json
  tracing_config = "Active"
}

# resource "aws_sns_topic_subscription" "this" {
#   topic_arn = aws_sns_topic.this.arn
#   protocol  = "sqs"
#   endpoint  = var.queue.arn
# }

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = "testtest@gmail.com"
}