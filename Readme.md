# Infrastructure Drift Detection and Automated Remediation using Terraform and AWS

## 1. Project Overview

This project demonstrates how to detect and automatically fix infrastructure
drift in AWS.

The infrastructure was created using Terraform. After deployment, a manual
change was made from the AWS Console to simulate configuration drift.

AWS Config detected the incorrect configuration and generated a compliance
event. Amazon EventBridge forwarded the event to an AWS Lambda function.
Lambda then restored the correct configuration.

## Architecture
![src1](./img/AWS%20Infrastructure%20Drift%20Detection%20Flow.png)

## 2. Objective

The main objectives of this project are:

- Create AWS infrastructure using Terraform.
- Simulate configuration drift manually.
- Detect the drift using AWS Config.
- Trigger automatic remediation using EventBridge and Lambda.
- Restore the correct configuration.
- Store Lambda execution logs in CloudWatch.


---

## 3. Technologies Used

- Terraform
- Amazon EC2
- Amazon VPC / Security Group
- Amazon S3
- AWS Config
- Amazon EventBridge
- AWS Lambda
- Amazon CloudWatch
- Python


---

# 4. Infrastructure Created Using Terraform

Terraform was used to create the following AWS resources:

### EC2 Instance

Name:

`Project-4-Server`

Instance type:

`t3.micro`

The EC2 instance is managed by Terraform.

### Security Group

Name:

`project-4-sg`

The Security Group allows:

- SSH - Port 22
- HTTP - Port 80
- Outbound traffic

### S3 Bucket

The project also contains an S3 bucket created using Terraform.

---

# 5. Terraform Files

The Terraform project contains:

```text
project-4/
│
├── provider.tf
├── main.tf
├── variable.tf
└── output.tf
```

# 6. Terraform Deployment

The Terraform infrastructure was initialized using:
```
terraform init
```
The configuration was checked using:
```
terraform validate
```
The planned changes were reviewed using:
```
terraform plan
```
![src2](./img/Screenshot%202026-10-03%20170328.png)

Finally, the infrastructure was created using:
```
terraform apply
```
![src3](./img/Screenshot%202026-10-03%20171100.png)
# 7. AWS Config Setup

AWS Config was used for drift detection.

A managed AWS Config rule was created:
```
project-4-required-tags
```
The rule checks whether the EC2 instance contains the required tag:
```
Key   = Environment
Value = Production
```

The rule was configured as a detective rule and evaluates configuration
changes.

# 8. Drift Simulation

To simulate real-world infrastructure drift, the EC2 tag was manually
changed from the AWS Console.

__Original configuration:__
```
Environment = Production
```
__Manual change:__

```
Environment = Testing
```
This change was not made through Terraform.

![src4](./img/Screenshot%202026-10-03%20171323.png)

Therefore, it represents configuration drift.

# 9. Drift Detection

__After changing the tag to:__
```
Environment = Testing
```
AWS Config evaluated the EC2 instance.

__The resource became:__
```
NON_COMPLIANT
```
This confirmed that AWS Config detected the configuration drift.

# 10. Lambda Remediation

__A Lambda function was created:__
```
project-4-drift-remediation
```
__Runtime:__
```
Python 3.14
```
The Lambda function restores the correct EC2 tag.

__Lambda Code__

```
import boto3

ec2 = boto3.client("ec2")

def lambda_handler(event, context):

    instance_id = "i-04d2ac27acd0112f"

    ec2.create_tags(
        Resources=[instance_id],
        Tags=[
            {
                "Key": "Environment",
                "Value": "Production"
            }
        ]
    )

    print(f"Remediated {instance_id}: Environment=Production")

    return {
        "statusCode": 200,
        "instance_id": instance_id,
        "message": "Environment tag restored to Production"
    }
```
The Lambda execution role was given permission to create tags on the
Project-4 EC2 instance.

# 11. IAM Permission for Lambda

The Lambda function needs permission to modify the EC2 tag.

__An IAM policy was attached to the Lambda execution role with the required
EC2 action:__
```
ec2:CreateTags
```
The permission was restricted to the Project-4 EC2 instance.

This allows Lambda to perform only the operation required for the
remediation.

The Lambda function was then tested successfully before connecting it to
the automatic workflow.
![src5](./img/Screenshot%202026-10-03%20182002.png)
# 12. EventBridge Automation

To make the remediation automatic, Amazon EventBridge was configured.

__EventBridge rule:__
```
project-4-auto-remediation
```
The rule listens for AWS Config compliance change events.

__The event pattern checks for:__

```
Source:
aws.config

Detail Type:
Config Rules Compliance Change

Compliance Type:
NON_COMPLIANT

Config Rule:
project-4-required-tags

Resource Type:
AWS::EC2::Instance

Resource:
Project-4 EC2 instance
```
__The target of the EventBridge rule is:__
```
project-4-drift-remediation
```
Therefore, when AWS Config detects the drift, EventBridge automatically
invokes the Lambda function.

# 13. Automatic Remediation Workflow

__The complete automatic process works as follows:__

### Step 1 — Approved Configuration

__Terraform creates the EC2 instance with:__
```
Environment = Production
```
### Step 2 — Manual Change

__The tag is manually changed:__
```
Production
     ↓
Testing
```
This creates infrastructure drift.

### Step 3 — AWS Config Detection

AWS Config evaluates the resource.

__The resource becomes:__
```
NON_COMPLIANT
```
### Step 4 — EventBridge Trigger

AWS Config sends a compliance change event.

EventBridge receives the event and checks whether it matches the
configured rule.

### Step 5 — Lambda Execution

__EventBridge invokes:__
```
project-4-drift-remediation
```
Lambda executes the `ec2:CreateTags` operation.

### Step 6 — Configuration Restoration

__The tag is changed back:__
```
Testing
    ↓
Production
```
### Step 7 — Logging

The Lambda execution is recorded in CloudWatch Logs.

# 14. CloudWatch Logging

CloudWatch Logs are used to monitor Lambda execution.

__The Lambda function creates logs in:__
```
/aws/lambda/project-4-drift-remediation
```
__A successful remediation produces a message similar to:__
```
Remediated i-04d2ac27acd0112f: Environment=Production
```
This log provides evidence that the remediation Lambda was executed and
attempted to restore the required configuration.

CloudWatch therefore provides visibility into the automatic remediation
process.
![src7](./img/Screenshot%202026-10-03%20204616.png)
# 15. Verification of Automatic Remediation

__The complete workflow is tested by manually changing:__
```
Environment = Production
```
__to:__
```
Environment = Testing
```
__The expected sequence is:__
```
Environment=Testing
        ↓
AWS Config
        ↓
NON_COMPLIANT
        ↓
EventBridge
        ↓
Lambda
        ↓
Environment=Production
```
After Lambda executes, the EC2 instance should again contain:
```
Environment = Production
```
This confirms that the drift was automatically remediated.

![src6](./img/Screenshot%202026-10-03%20182946.png)

# 16. Project Workflow

The project can be summarized in five major stages.

### Stage 1 — Provision

Terraform creates the required AWS infrastructure.

`Terraform → EC2 + Security Group + S3`
### Stage 2 — Drift

A manual change is made from the AWS Console.

`Production → Testing`
### Stage 3 — Detect

AWS Config checks the resource and identifies the incorrect configuration.

`AWS Config → NON_COMPLIANT`
### Stage 4 — Remediate

EventBridge triggers Lambda.

`EventBridge → Lambda → Production`
### Stage 5 — Monitor

CloudWatch records the Lambda execution.

`Lambda → CloudWatch Logs`

# Final Output

__After the automatic remediation, the Project-4 EC2 instance tags should show:__
```
Name         = Project-4-Server
Environment  = Production
```
__This confirms that the manually introduced drift:__

```
Production → Testing
```
__was automatically restored to:__
```
Testing → Production
```
# Project Summary

This project implements Infrastructure Drift Detection and Automated Remediation using Terraform and AWS Lambda.

Terraform is used to create the AWS infrastructure, including an EC2 instance, Security Group, and S3 bucket. A manual change is then made to the EC2 tag to simulate infrastructure drift. AWS Config detects the change and marks the resource as NON_COMPLIANT.

The compliance event is sent through Amazon EventBridge, which automatically triggers an AWS Lambda function. Lambda restores the required EC2 configuration by changing the Environment tag back to Production. The Lambda execution is recorded in CloudWatch Logs.

### Complete Workflow
```
Terraform
    ↓
AWS Infrastructure
    ↓
Manual Drift
    ↓
AWS Config
    ↓
NON_COMPLIANT
    ↓
EventBridge
    ↓
Lambda
    ↓
Environment = Production
    ↓
CloudWatch Logs
```