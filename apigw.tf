resource "aws_api_gateway_rest_api" "endpoint" {
  name        = "lifx-proxy"
  description = "API for lifx-proxy lambda function"
}

resource "aws_api_gateway_stage" "lifx" {
  stage_name    = "lifx"
  rest_api_id   = "${aws_api_gateway_rest_api.endpoint.id}"
  deployment_id = "${aws_api_gateway_deployment.endpoint.id}"
  tags = "${var.tags}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.endpoint.id}"
  resource_id   = "${aws_api_gateway_rest_api.endpoint.root_resource_id}"
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = "true"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.endpoint.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lifx.invoke_arn}"
}

resource "aws_api_gateway_deployment" "endpoint" {
  depends_on = [
    "aws_api_gateway_integration.lambda_root"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.endpoint.id}"
  stage_name  = "lifx"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lifx.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /POST/* portion grants access from POST method on any resource within
  # the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.endpoint.execution_arn}/POST/*"
}

# Usage plan is required for API key
resource "aws_api_gateway_usage_plan" "lifx-usage-plan" {
  name = "lifx-usage-plan"
  api_stages {
    api_id = "${aws_api_gateway_rest_api.endpoint.id}"
    stage  = "${aws_api_gateway_deployment.endpoint.stage_name}"
  }
throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }
}

resource "aws_api_gateway_api_key" "lifx-api-key" {
  name = "lifx-api-key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = "${aws_api_gateway_api_key.lifx-api-key.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.lifx-usage-plan.id}"
}
