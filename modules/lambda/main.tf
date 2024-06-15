data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "allow_s3_object_actions" {
  statement {
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = ["${var.bucket.arn}"]
  }
  statement {
    effect = "Allow"
    actions = ["s3:*Object"]
    resources = ["${var.bucket.arn}/*"]
  }
}

data "aws_iam_policy_document" "allow_sqs_receive" {
  statement {
    effect = "Allow"
    actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = ["${var.queue.arn}"]
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "${local.prefix}-lambda-execution-role"
}

resource "aws_iam_policy" "allow_s3_object_actions_policy" {
  name        = "${local.prefix}-allow-s3-object-actions-policy"
  description = "${local.prefix}-allow-s3-object-actions-policy"
  policy      = data.aws_iam_policy_document.allow_s3_object_actions.json
}

resource "aws_iam_policy" "allow_sqs_receive_policy" {
  name        = "${local.prefix}-allow-sqs-receive-policy"
  description = "${local.prefix}-allow-sqs-receive-policy"
  policy      = data.aws_iam_policy_document.allow_sqs_receive.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_execution_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "attach_x_ray_write_only_action_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "attach_allow_s3_object_actions_policy" {
  policy_arn = aws_iam_policy.allow_s3_object_actions_policy.arn
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "attach_allow_sqs_receive_policy" {
  policy_arn = aws_iam_policy.allow_sqs_receive_policy.arn
  role       = aws_iam_role.this.name
}

resource "null_resource" "update_layer_trigger" {
  for_each = toset(local.layers)

  triggers = {
    "requirements_diff" = filebase64("${path.module}/layers/${each.key}/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOF
      venv_activator="${path.module}/layers/${each.key}/.venv/bin/activate"
      archive_path="${path.module}/layers/${each.key}/archive"
      export_path="${path.module}/layers/${each.key}/archive/python"
    
      if [[ -f "$venv_activator" ]]; then
        echo "python virtual environment found"
        source "$venv_activator"
      fi
      
      rm -rf "$archive_path"
      mkdir -p "$export_path"
      pip install -r "${path.module}/layers/${each.key}/requirements.txt" -t "$export_path" --no-cache-dir
    EOF

    on_failure = fail
  }
}

data "archive_file" "archive_layers" {
  for_each = toset(local.layers)

  depends_on = [
    null_resource.update_layer_trigger,
  ]

  type        = "zip"
  source_dir  = "${path.module}/layers/${each.key}/archive"
  output_path = "${path.module}/layers/${each.key}/archive.zip"
}

resource "aws_lambda_layer_version" "this" {
  for_each = toset(local.layers)

  filename   = data.archive_file.archive_layers[each.key].output_path
  layer_name = replace(each.key, "_", "-")

  compatible_runtimes = ["python3.11"]
}

data "archive_file" "this" {
  for_each = toset(local.funtions)

  type        = "zip"
  source_dir  = "${path.module}/${each.key}/src"
  output_path = "${path.module}/${each.key}/${each.key}.zip"
}

resource "aws_lambda_function" "this" {
  for_each = toset(local.funtions)

  function_name    = "${local.prefix}-${each.key}"
  filename         = data.archive_file.this[each.key].output_path
  role             = aws_iam_role.this.arn
  handler          = "${each.key}.handler"
  source_code_hash = data.archive_file.this[each.key].output_base64sha256
  runtime          = "python3.11"
  layers           = [for layer in aws_lambda_layer_version.this : layer.arn] 
  tracing_config {
    mode = "Active"
  }
  
  environment {
    variables = {
      S3_Bucket = var.bucket.id
    }
  }
}

resource "aws_lambda_permission" "this" {
  statement_id  = "${local.prefix}-schedule-event-statement"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this["s3-file-creator"].arn
  principal     = "events.amazonaws.com"
  source_arn    = var.periodic_event.arn
}