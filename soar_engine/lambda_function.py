import json
import logging
from remediations.s3_remediator import remediate_s3_acl
from remediations.iam_remediator import remediate_iam_policy
from remediations.ec2_remediator import remediate_sg_ingress

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("ALERT: Security Event Received by SOAR Router")
    
    try:
        detail = event.get('detail', {})
        event_name = detail.get('eventName')
        
        # Route 1: Storage Misconfigurations
        if event_name in ['PutBucketAcl', 'PutBucketPublicAccessBlock']:
            logger.info("Routing to S3 Remediator Module...")
            return remediate_s3_acl(detail, context)
            
        # Route 2: IAM Privilege Escalation
        elif event_name == 'AttachUserPolicy':
            logger.info("Routing to IAM Remediator Module...")
            return remediate_iam_policy(detail, context)
            
        # Route 3: Network Exposure
        elif event_name == 'AuthorizeSecurityGroupIngress':
            logger.info("Routing to EC2 Remediator Module...")
            return remediate_sg_ingress(detail, context)
            
        else:
            logger.info(f"Event ignored or unsupported. Type: {event_name}")
            return {'statusCode': 200, 'body': json.dumps('Event ignored.')}
            
    except Exception as e:
        logger.error(f"Router failed to process event: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps(f"Error: {str(e)}")}