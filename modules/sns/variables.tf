variable "env" {}
variable "project" {}
variable "msg_src" {}
variable "queue" {}

locals {
  prefix = "${var.project}-${var.env}"
}