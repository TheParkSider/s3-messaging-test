variable "env" {}
variable "project" {}
variable "topic" {}

locals {
  prefix = "${var.project}-${var.env}"
}