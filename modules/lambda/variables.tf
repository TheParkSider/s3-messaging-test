variable "env" {}
variable "project" {}
variable "bucket" {}
variable "periodic_event" {}
variable "queue" {}

locals {
  prefix = "${var.project}-${var.env}"
  funtions = [
    "s3-file-creator",
    "sms-receiver",
    "sqs-receiver",
  ]
  layers = [
    "aws-xray-sdk"
  ]
}