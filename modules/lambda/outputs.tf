output "functions" {
  value = { for f in local.funtions : f => aws_lambda_function.this[f] }
}