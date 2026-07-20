import boto3
import json
import logging
from integrations.splunk_hec import send_to_splunk

logger = logging.getLogger()
logger.setLevel(logging.INFO)
ec2_client = boto3.client('ec2')

def remediate_sg_ingress(detail, context):
    request_parameters = detail.get('requestParameters', {})
    group_id = request_parameters.get('groupId')
    ip_permissions = request_parameters.get('ipPermissions', {})
    
    if not group_id or not ip_permissions:
        logger.warning("Missing groupId or ipPermissions in payload.")
        return {'statusCode': 400, 'body': "Missing EC2 parameters"}
        
    logger.info(f"Target Security Group: {group_id}. Executing remediation...")
    
    try:
        permissions_list = ip_permissions.get('items', [])
        
        if not permissions_list:
            logger.warning("No IP permissions found to revoke.")
            return {'statusCode': 400, 'body': "Empty permissions list"}

        # Fix: Convert CloudTrail camelCase to boto3 PascalCase
        boto3_permissions = []
        for perm in permissions_list:
            formatted_perm = {
                'IpProtocol': perm.get('ipProtocol'),
                'FromPort': perm.get('fromPort'),
                'ToPort': perm.get('toPort'),
                'IpRanges': [{'CidrIp': r.get('cidrIp')} for r in perm.get('ipRanges', {}).get('items', [])]
            }
            boto3_permissions.append(formatted_perm)

        # Revoke the unauthorized ingress rule
        ec2_client.revoke_security_group_ingress(
            GroupId=group_id,
            IpPermissions=boto3_permissions
        )
        
        # Generate the structured report
        incident_report = {
            "Incident ID": context.aws_request_id,
            "Time Detected": detail.get('eventTime', 'Unknown'),
            "Detection": "Unauthorized Public SSH/RDP Exposure",
            "MITRE ATT&CK": "T1021 (Remote Services)",
            "Affected Resource": f"Security Group: {group_id}",
            "Severity": "High",
            "Action Taken": "Revoked unauthorized ingress rule",
            "Remediation Success": True
        }
        
        logger.info("=== INCIDENT REPORT ===")
        logger.info(json.dumps(incident_report, indent=2))
        
        # Forward to Splunk
        send_to_splunk(incident_report)
        
        return {'statusCode': 200, 'body': json.dumps('EC2 Remediation successful.')}
        
    except Exception as e:
        logger.error(f"EC2 Remediation failed: {str(e)}")
        raise e
