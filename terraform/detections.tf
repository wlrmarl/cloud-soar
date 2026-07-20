resource "aws_cloudwatch_event_rule" "s3_exposure_rule" {
  name        = "detect-s3-public-exposure"
  description = "Triggers Lambda when S3 bucket ACLs are modified"
  
  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName   = ["PutBucketAcl", "PutBucketPublicAccessBlock"]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_exposure_rule.name
  target_id = "SOAREngine"
  arn       = aws_lambda_function.soar_remediation_engine.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_remediation_engine.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_exposure_rule.arn
}

resource "aws_cloudwatch_event_rule" "iam_privilege_escalation" {
  name        = "detect-iam-privilege-escalation"
  description = "Triggers Lambda when IAM policies are attached to users"
  
  event_pattern = jsonencode({
    source = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName   = ["AttachUserPolicy"]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_lambda_iam" {
  rule      = aws_cloudwatch_event_rule.iam_privilege_escalation.name
  target_id = "SOAREngineIAM"
  arn       = aws_lambda_function.soar_remediation_engine.arn
}

resource "aws_lambda_permission" "allow_eventbridge_iam" {
  statement_id  = "AllowExecutionFromEventBridgeIAM"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_remediation_engine.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iam_privilege_escalation.arn
}

resource "aws_cloudwatch_event_rule" "ec2_network_exposure" {
  name        = "detect-ec2-public-exposure"
  description = "Triggers Lambda when Security Group ingress rules are modified"
  
  event_pattern = jsonencode({
    source = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["AuthorizeSecurityGroupIngress"]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_lambda_ec2" {
  rule      = aws_cloudwatch_event_rule.ec2_network_exposure.name
  target_id = "SOAREngineEC2"
  arn       = aws_lambda_function.soar_remediation_engine.arn
}

resource "aws_lambda_permission" "allow_eventbridge_ec2" {
  statement_id  = "AllowExecutionFromEventBridgeEC2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_remediation_engine.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_network_exposure.arn
}