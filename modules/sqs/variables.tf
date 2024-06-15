variable "env" {}
variable "project" {}

locals {
  prefix = "${var.project}-${var.env}"
}