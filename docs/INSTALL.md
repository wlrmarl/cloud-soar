# Installing Cloud-SOAR

This guide walks through deploying Cloud Security Automation Framework (Cloud-SOAR) in a local development environment using LocalStack, Terraform, Docker, and Splunk Enterprise.

By the end of this guide you will have:

- A fully configured Splunk Enterprise instance
- Local AWS infrastructure provisioned using Terraform
- Cloud-SOAR orchestration engine deployed
- CloudTrail and EventBridge detection pipeline configured
- Automated remediation workflows ready for execution

> **Note**
>
> Cloud-SOAR is designed around native AWS services. This guide uses LocalStack to provide a reproducible local development environment. The same architecture can be deployed to an AWS account with minimal configuration changes.

---

# Installation Overview

The installation process consists of six stages:

1. Clone the repository
2. Configure environment variables
3. Start Splunk Enterprise
4. Provision Splunk resources
5. Deploy Cloud-SOAR infrastructure
6. Verify the deployment

---

# Prerequisites

Before installing Cloud-SOAR ensure the following software is available on your system.

| Software | Version |
|----------|---------|
| Docker | Latest |
| Docker Compose | Latest |
| LocalStack CLI | Latest |
| Terraform | >= 1.6 |
| Python | >= 3.11 |
| AWS CLI | Latest |
| Git | Latest |

Verify your installation.

```bash
docker --version
docker compose version
terraform version
python --version
aws --version
git --version
```

---

# Clone the Repository

```bash
git clone https://github.com/wlrmarl/cloud-soar.git

cd cloud-soar
```

---

# Start Splunk Enterprise

Navigate into the Splunk deployment directory.
```bash
cd splunk_setup
```

Create a .env file
```bash 
touch .env
```

Add below environment variables which will be setup automatically.
```
SPLUNK_PASSWORD=P@ssw0rd1234!
SPLUNK_TOKEN=317ad772-2abc-4bc3-9d3f-ee5d6ddfbf2b
```
Above is the example, Please replace with your desired values.

Start the container.
```bash
docker compose up -d
```

Verify the container is running.
```bash
docker ps
```

Expected output:
```text
splunk-enterprise
STATUS: Up
```
Wait until Splunk has completed its initialization before continuing.

Cloud-SOAR automatically creates the required HTTP Event Collector and dashboard.
Execute:
```bash
./provision_splunk.sh
```
When the script completes you should see confirmation.
Verify the Splunk Web UI is accessible on your host(http://localhost:8000) login with username `admin` and your configured password

--- 

# Deploy on LocalStack
Before proceeding further, decide the deployment environment  local (localstack) or AWS Cloud

In both cases u must configure your awscli with proper credentials, if using localstack then u must install awslocal and tflocal and proceed further.

The guide is built on running it locally on localstack but running on aws is exactly similar with only change being instead of using local tools such as awslocal and tflocal u must use real utility such as aws cli and terraform.

Configure localstack after creating account from https://app.localstack.cloud/getting-started
 
After installing localstack cli and properly configured, start localstack with

```bassh
localstack start -d
```
# Configure Terraform Variables

Create a Terraform variable file.

```bash
cd terraform
touch terraform.tfvars
```
Add the following variables:
```
splunk_hec_url = "https://<SPLUNK_HOST:8088/services/collector/event"
splunk_token   = "<SPLUNK_TOKEN"
```
Update the values of SPLUNK_HOST set it to your splunk instance ip from where splunk is accesible and splunk_token is the one we created while provisioning splunk.

---

# Deploy Cloud-SOAR Infrastructure

Initialize Terraform.

```bash
tflocal init
```

Deploy the platform.
```bash
terraform apply
```

Type:
```text
yes
```

Terraform will provision:

- IAM resources
- S3 bucket
- EC2 simulation resources
- CloudTrail
- EventBridge rules
- Cloud-SOAR Orchestration Engine
- Required IAM roles

---

# Installation Complete

Cloud-SOAR has now been deployed successfully.

You can verify by checking provisioned resources on localstack web ui and also check Splunk Http Data Input.

Continue with the Usage Guide to execute attack simulations and observe automated detection and remediation workflows.