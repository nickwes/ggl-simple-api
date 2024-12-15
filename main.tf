provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table using Provisioned mode (to utilize the Free Tier)
resource "aws_dynamodb_table" "log_table" {
  name           = "LogTable"
  hash_key       = "ID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 25  # 25 RCUs (Free Tier)
  write_capacity = 25  # 25 WCUs (Free Tier)

  attribute {
    name = "ID"
    type = "S"
  }
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "log_service_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "dynamodb_full" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Lambda Function 1 - Save Log
resource "aws_lambda_function" "save_log" {
  filename         = "save_log.zip"
  function_name    = "SaveLogFunction"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "save_log.handler"
  source_code_hash = filebase64sha256("save_log.zip")
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.log_table.name
    }
  }

  # Added memory size and timeout to optimize function use within free tier
  memory_size = 128  # Default (1GB is too high for basic functions)
  timeout     = 5    # Set a timeout
}

# Lambda Function 2 - Retrieve Logs
resource "aws_lambda_function" "retrieve_logs" {
  filename         = "retrieve_logs.zip"
  function_name    = "RetrieveLogsFunction"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "retrieve_logs.handler"
  source_code_hash = filebase64sha256("retrieve_logs.zip")
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.log_table.name
    }
  }

  # Added memory size and timeout to optimize function use within free tier
  memory_size = 128  # Default (1GB is too high for basic functions)
  timeout     = 5    # Set a timeout
}

# API Gateway
resource "aws_apigatewayv2_api" "log_service_api" {
  name          = "LogServiceAPI"
  protocol_type = "HTTP"
}

# API Integration for SaveLog
resource "aws_apigatewayv2_integration" "save_log_integration" {
  api_id           = aws_apigatewayv2_api.log_service_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.save_log.invoke_arn
}

resource "aws_apigatewayv2_route" "save_log_route" {
  api_id    = aws_apigatewayv2_api.log_service_api.id
  route_key = "POST /log"
  target    = "integrations/${aws_apigatewayv2_integration.save_log_integration.id}"
}

# API Integration for RetrieveLogs
resource "aws_apigatewayv2_integration" "retrieve_logs_integration" {
  api_id           = aws_apigatewayv2_api.log_service_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.retrieve_logs.invoke_arn
}

resource "aws_apigatewayv2_route" "retrieve_logs_route" {
  api_id    = aws_apigatewayv2_api.log_service_api.id
  route_key = "GET /logs"
  target    = "integrations/${aws_apigatewayv2_integration.retrieve_logs_integration.id}"
}

# Create CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.log_service_api.name}"
  retention_in_days = 1
}

# Enable logging for the API Gateway stage
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.log_service_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp               = "$context.identity.sourceIp"
      requestTime            = "$context.requestTime"
      protocol              = "$context.protocol"
      httpMethod            = "$context.httpMethod"
      routeKey              = "$context.routeKey"
      status                = "$context.status"
      responseLength        = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "api_gw_save_log" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_log.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.log_service_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_retrieve_logs" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retrieve_logs.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.log_service_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}
