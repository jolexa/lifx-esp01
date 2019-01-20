data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/lifx-proxy.py"
  output_path = "/tmp/lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "lifx" {
name = "/aws/lambda/${aws_lambda_function.lifx.function_name}"
retention_in_days = "14"
tags = "${var.tags}"
}

resource "aws_lambda_function" "lifx" {
  function_name = "lifx-proxy"
  description = "Proxy function to send commands to LIFX API"
  filename         = "/tmp/lambda_function.zip"
  role             = "${aws_iam_role.lambda_exec.arn}"
  handler          = "lifx-proxy.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "python3.7"
  memory_size      = 128
  timeout          = 30
  tags             = "${var.tags}"

  environment {
    variables = {
      api_key = "placeholder"
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function may
# access.
resource "aws_iam_role" "lambda_exec" {
  name = "lifx-proxy-role"
  description = "Role for lifx-proxy function"
  tags = "${var.tags}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "basic-exec" {
  role       = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
