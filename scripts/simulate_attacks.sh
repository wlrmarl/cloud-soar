#!/bin/bash

# ==============================================================================
# AWS Cloud-SOAR: Automated Attack Simulation & Remediation Testing Suite
# ==============================================================================

echo "====================================================="
echo "🚨 Starting AWS Cloud-SOAR Attack Simulation Suite 🚨"
echo "====================================================="

# ---------------------------------------------------------
# 1. Fetch Dynamic Victim Resources
# ---------------------------------------------------------
echo -e "\n[*] Fetching victim resources from LocalStack..."

# Extract the dynamic bucket name using AWS CLI querying
BUCKET_NAME=$(awslocal s3api list-buckets --query "Buckets[?starts_with(Name, 'soar-victim-bucket')].Name" --output text)
# Extract the Security Group ID
SG_ID=$(awslocal ec2 describe-security-groups --group-names soar-victim-sg --query "SecurityGroups[0].GroupId" --output text)
IAM_USER="soar-victim-user"

if [ -z "$BUCKET_NAME" ] || [ -z "$SG_ID" ]; then
    echo "❌ Error: Could not find Terraform victim resources. Did you run 'tflocal apply'?"
    exit 1
fi

echo "    - Target S3 Bucket: $BUCKET_NAME"
echo "    - Target IAM User: $IAM_USER"
echo "    - Target Security Group: $SG_ID"

# ---------------------------------------------------------
# 2. Simulate T1537: S3 Public Exposure
# ---------------------------------------------------------
echo -e "\n[1] Simulating T1537: Exposing S3 Bucket to Public..."
awslocal s3api put-bucket-acl --bucket $BUCKET_NAME --acl public-read

echo "    -> Triggering SOAR Engine (Mock CloudTrail Event)..."
cat <<EOF > mock_s3_event.json
{
  "source": "aws.s3",
  "detail": {
    "eventName": "PutBucketAcl",
    "requestParameters": {
      "bucketName": "$BUCKET_NAME"
    }
  }
}
EOF
awslocal lambda invoke --function-name Cloud_SOAR_Engine --cli-binary-format raw-in-base64-out --payload file://mock_s3_event.json response.json > /dev/null

echo "    -> Verifying Remediation..."
# The SOAR engine should have reverted it to private. If we get AccessDenied or private ACL, it worked.
awslocal s3api get-bucket-acl --bucket $BUCKET_NAME | grep -q "FULL_CONTROL"
if [ $? -eq 0 ]; then
    echo "    ✅ SUCCESS: S3 Bucket ACL reverted to private."
else
    echo "    ❌ FAILED: S3 Bucket is still exposed!"
fi

# ---------------------------------------------------------
# 3. Simulate T1098: IAM Privilege Escalation
# ---------------------------------------------------------
echo -e "\n[2] Simulating T1098: Attaching AdministratorAccess to Victim User..."
awslocal iam attach-user-policy --user-name $IAM_USER --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "    -> Triggering SOAR Engine (Mock CloudTrail Event)..."
cat <<EOF > mock_iam_event.json
{
  "source": "aws.iam",
  "detail": {
    "eventName": "AttachUserPolicy",
    "requestParameters": {
      "userName": "$IAM_USER",
      "policyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  }
}
EOF
awslocal lambda invoke --function-name Cloud_SOAR_Engine --cli-binary-format raw-in-base64-out --payload file://mock_iam_event.json response.json > /dev/null

echo "    -> Verifying Remediation..."
# The SOAR engine should have detached the policy
POLICY_CHECK=$(awslocal iam list-attached-user-policies --user-name $IAM_USER --query "AttachedPolicies[?PolicyName=='AdministratorAccess'].PolicyName" --output text)
if [ -z "$POLICY_CHECK" ]; then
    echo "    ✅ SUCCESS: AdministratorAccess policy was stripped from the user."
else
    echo "    ❌ FAILED: User still has AdministratorAccess!"
fi

# ---------------------------------------------------------
# 4. Simulate T1021: EC2 SSH Exposure
# ---------------------------------------------------------
echo -e "\n[3] Simulating T1021: Opening SSH (Port 22) to 0.0.0.0/0..."
awslocal ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null

echo "    -> Triggering SOAR Engine (Mock CloudTrail Event)..."
cat <<EOF > mock_sg_event.json
{
  "source": "aws.ec2",
  "detail": {
    "eventName": "AuthorizeSecurityGroupIngress",
    "requestParameters": {
      "groupId": "$SG_ID",
      "ipPermissions": {
        "items": [{"ipProtocol": "tcp", "fromPort": 22, "toPort": 22, "ipRanges": {"items": [{"cidrIp": "0.0.0.0/0"}]}}]
      }
    }
  }
}
EOF
awslocal lambda invoke --function-name Cloud_SOAR_Engine  --cli-binary-format raw-in-base64-out --payload file://mock_sg_event.json response.json > /dev/null

echo "    -> Verifying Remediation..."
# The SOAR engine should have removed the 0.0.0.0/0 rule
SG_CHECK=$(awslocal ec2 describe-security-groups --group-ids $SG_ID --query "SecurityGroups[0].IpPermissions[?ToPort==\`22\`].IpRanges[?CidrIp=='0.0.0.0/0'].CidrIp" --output text)
if [ -z "$SG_CHECK" ]; then
    echo "    ✅ SUCCESS: Rogue SSH rule revoked."
else
    echo "    ❌ FAILED: Security Group is still open to the internet!"
fi

# ---------------------------------------------------------
# 5. Cleanup Artifacts
# ---------------------------------------------------------
echo -e "\n[*] Cleaning up mock event files..."
rm mock_s3_event.json mock_iam_event.json mock_sg_event.json response.json

echo -e "\n🎉 Simulation Complete! Check Splunk SIEM for Incident Reports."
echo "====================================================="