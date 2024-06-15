resource "aws_cloudwatch_event_rule" "this" {
  name        = "${local.prefix}-schedule-event"
  description = "${local.prefix}-schedule-event"
  state       = "DISABLED"
  
  schedule_expression = "cron(0/1 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "this" {
  rule = aws_cloudwatch_event_rule.this.name
  arn = var.callee.arn
  
  input = "{}"
}
