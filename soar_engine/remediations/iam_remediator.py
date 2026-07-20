import boto3
import json
import logging
from integrations.splunk_hec import send_to_splunk

logger = logging.getLogger()
logger.setLevel(logging.INFO)
iam_client = boto3.client('iam')

def remediate_iam_policy(detail, context):
    request_parameters = detail.get('requestParameters', {})
    user_name = request_parameters.get('userName')
    policy_arn = request_parameters.get('policyArn')
    
    if not user_name or not policy_arn:
        logger.warning("Missing userName or policyArn in payload.")
        return {'statusCode': 400, 'body': "Missing IAM parameters"}
        
    logger.info(f"Target User: {user_name}. Policy: {policy_arn}. Executing remediation...")
    
    try:
        # Detach the unauthorized policy
        iam_client.detach_user_policy(UserName=user_name, PolicyArn=policy_arn)
        
        # Generate the structured report
        incident_report = {
            "Incident ID": context.aws_request_id,
            "Time Detected": detail.get('eventTime', 'Unknown'),
            "Detection": "Unauthorized IAM Policy Attachment",
            "MITRE ATT&CK": "T1098 (Account Manipulation)",
            "Affected Resource": f"User: {user_name}",
            "Severity": "Critical",
            "Action Taken": f"Detached policy {policy_arn}",
            "Remediation Success": True
        }
        
        logger.info("=== INCIDENT REPORT ===")
        logger.info(json.dumps(incident_report, indent=2))
        
        # Forward to Splunk
        send_to_splunk(incident_report)
        
        return {'statusCode': 200, 'body': json.dumps('IAM Remediation successful.')}
        
    except Exception as e:
        logger.error(f"IAM Remediation failed: {str(e)}")
        raise e