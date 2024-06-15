variable "env" {}
variable "project" {}
variable "callee" {}

locals {
  prefix = "${var.project}-${var.env}"
}