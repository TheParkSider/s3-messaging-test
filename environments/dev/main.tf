module "lambda" {
  source         = "../../modules/lambda"
  env            = local.env
  project        = local.project
  bucket         = module.s3.bucket
  periodic_event = module.event.periodic_event
  queue          = module.sqs.queue
}

module "s3" {
  source  = "../../modules/s3"
  env     = local.env
  project = local.project
  topic   = module.sns.topic
}

module "event" {
  source   = "../../modules/event"
  env      = local.env
  project  = local.project
  callee   = module.lambda.functions["s3-file-creator"]
}

module "sns" {
  source  = "../../modules/sns"
  env     = local.env
  project = local.project
  msg_src = module.s3.bucket
  queue   = module.sqs.queue
}

module "sqs" {
  source  = "../../modules/sqs"
  env     = local.env
  project = local.project
}