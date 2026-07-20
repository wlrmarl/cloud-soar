resource "aws_iam_role" "lambda_execution_role" {
  name = "soar_lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../soar_engine"
  output_path = "${path.module}/lambda_payload.zip"
}

resource "aws_lambda_function" "soar_remediation_engine" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "Cloud_SOAR_Engine"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  
  environment {
    variables = {
      SPLUNK_TOKEN   = var.splunk_token
      SPLUNK_HEC_URL = var.splunk_hec_url
    }
  }
}
