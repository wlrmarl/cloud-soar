import boto3
import json
import logging
from integrations.splunk_hec import send_to_splunk

logger = logging.getLogger()
logger.setLevel(logging.INFO)
s3_client = boto3.client('s3')

def remediate_s3_acl(detail, context):
    request_parameters = detail.get('requestParameters', {})
    bucket_name = request_parameters.get('bucketName')
    
    if not bucket_name:
        logger.warning("Bucket name not found in payload.")
        return {'statusCode': 400, 'body': "Missing bucket name"}
        
    logger.info(f"Target Bucket: {bucket_name}. Executing remediation...")
    
    try:
        # Revert the bucket ACL to private
        s3_client.put_bucket_acl(Bucket=bucket_name, ACL='private')
        
        # Generate the structured report
        incident_report = {
            "Incident ID": context.aws_request_id,
            "Time Detected": detail.get('eventTime', 'Unknown'),
            "Detection": "Unauthorized S3 Bucket ACL Change",
            "MITRE ATT&CK": "T1537 (Cloud Data Exposure)",
            "Affected Resource": bucket_name,
            "Severity": "High",
            "Action Taken": "Reverted Bucket ACL to private",
            "Remediation Success": True
        }
        
        logger.info("=== INCIDENT REPORT ===")
        logger.info(json.dumps(incident_report, indent=2))
        
        # Forward to Splunk
        send_to_splunk(incident_report)
        
        return {'statusCode': 200, 'body': json.dumps('S3 Remediation successful.')}
        
    except Exception as e:
        logger.error(f"S3 Remediation failed: {str(e)}")
        raise e