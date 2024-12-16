# ggl-simple-api - a simple API to save and retrieve logs

## Local Terraform Deployment

1. Prerequisites:
   * Install Terraform
   * Install AWS CLI
   * Configure AWS CLI with credentials using aws configure

2. Prepare the Lambda Functions:
   * This step can be skipped if the deployment packages are already created
   * Zip the two python files found in the root directory function file individually:
     ```bash
     zip save_log.zip save_log.py
     zip retrieve_logs.zip retrieve_logs.py
     ```

3. Deploy the Solution:
   * Clone or copy the Terraform code into a directory
   * Place the save_log.zip and retrieve_logs.zip files in the same directory as the Terraform script
   * Initialize the Terraform environment:
     ```bash
     terraform init
     ```
   * Plan the deployment:
     ```bash
     terraform plan
     ```
   * Apply the deployment:
     ```bash
     terraform apply
     ```
   * Once deployed, Terraform will output the API endpoint URL

4. Test the API:
   * Use curl or a REST client (e.g., Postman) to interact with the API
   * Save a Log:
     ```bash
     curl -X POST -H "Content-Type: application/json" -d '{"ID": "123", "message": "Test log"}' <API_ENDPOINT>/log
     ```
   * Retrieve Logs:
     ```bash
     curl -X GET <API_ENDPOINT>/logs
     ```

5. Clean Up:
   * To avoid incurring charges, destroy the infrastructure:
     ```bash
     terraform destroy
     ```

## Pipeline Overview

The GitHub Actions workflow will:

1. Set up Terraform in the pipeline environment
2. Authenticate with AWS
3. Initialize the Terraform backend
4. Apply the changes to deploy the infrastructure

## Prerequisites

1. AWS Account:
   * An AWS account with access to the Free Tier

2. Terraform State Storage:
   * The code will use Terraform's default state in the repository

3. GitHub Secrets:
   * Add the following secrets to your repository in Settings > Secrets and variables > Actions > New repository secret:
   * AWS_SECRET_ACCESS_KEY: Your AWS secret key
   * AWS_REGION: Your AWS region (e.g., us-east-1)

## Required AWS Permissions

The AWS user linked to the AWS secrets needs the following permissions to execute this pipeline:

### IAM Permissions
* `iam:CreateRole`
* `iam:DeleteRole`
* `iam:GetRole`
* `iam:PutRolePolicy`
* `iam:DeleteRolePolicy`
* `iam:AttachRolePolicy`
* `iam:DetachRolePolicy`

### Lambda Permissions
* `lambda:CreateFunction`
* `lambda:DeleteFunction`
* `lambda:GetFunction`
* `lambda:UpdateFunctionCode`
* `lambda:UpdateFunctionConfiguration`
* `lambda:AddPermission`
* `lambda:RemovePermission`

### DynamoDB Permissions
* `dynamodb:CreateTable`
* `dynamodb:DeleteTable`
* `dynamodb:DescribeTable`
* `dynamodb:UpdateTable`

### API Gateway Permissions
* `apigateway:DELETE`
* `apigateway:GET`
* `apigateway:PATCH`
* `apigateway:POST`
* `apigateway:PUT`

### CloudWatch Permissions
* `logs:CreateLogGroup`
* `logs:DeleteLogGroup`
* `logs:PutRetentionPolicy`
* `logs:DescribeLogGroups`

You can create an IAM policy with these permissions or use the following managed policies:
* `AWSLambdaFullAccess`
* `AmazonDynamoDBFullAccess`
* `AmazonAPIGatewayAdministrator`
* `CloudWatchLogsFullAccess`
* `IAMFullAccess`

Note: While using *FullAccess policies is easier, it's recommended to create a custom policy with only the required permissions for better security.   

## Folder Structure

```
├── save_log.py         # Source code for saving logs Lambda function
├── retrieve_logs.py    # Source code for retrieving logs Lambda function
├── save_log.zip        # Deployment package for save_log Lambda 
├── retrieve_logs.zip   # Deployment package for retrieve Lambda 
├── main.tf            # Terraform configuration file
├── .github/
│   └── workflows/
│       └── deploy.yml # GitHub Actions workflow file
```

### Source Files vs Deployment Packages
* `.py files`: These are the source code files that contain the Lambda function logic
  - `save_log.py`: Contains the code for saving logs to DynamoDB
  - `retrieve_logs.py`: Contains the code for retrieving logs from DynamoDB

* `.zip files`: These are deployment packages required by AWS Lambda
  - Have already been generated from the .py files
  
## How to Run the Pipeline

1. Commit Changes:
   * Commit your artifacts folder, Terraform files, and the GitHub Actions workflow to the main branch:
     ```bash
     git add .
     git commit -m "Add pipeline for deploying log service"
     git push origin main
     ```

2. Trigger the Workflow:
   * The pipeline will automatically run when changes are pushed to the main branch

3. Monitor Progress:
   * Go to Actions in your GitHub repository to monitor the pipeline's progress
   * Check logs for steps like Terraform Init, Terraform Plan, and Terraform Apply

## Testing the API

After the deployment pipeline completes:

1. API Gateway Endpoint:
   * The api_endpoint output will be displayed in the Terraform Apply logs
   * Use it to test the API as described earlier

2. Test the Lambda Functions:
   * Follow the API testing steps using curl or Postman

## Rollback

To destroy the deployed infrastructure, run the following command locally or modify the pipeline to include a terraform destroy job:
```bash
terraform destroy -auto-approve
```

## A note about Terraform States

### Pipeline vs. Local Execution

1. **Pipeline Execution**:
   - When you run Terraform through the CI/CD pipeline (GitHub Actions), Terraform stores the state file (terraform.tfstate) locally in the directory where Terraform is executed.
   - In the context of GitHub Actions, this means the state file will be stored on the ephemeral GitHub Actions runner.
   - The runner is destroyed after the workflow run, so the state file is lost.
   - This means that the state file is not available locally, and any resources created or modified by the pipeline will not be reflected in your local Terraform state.

2. **Local Execution**:
   - If you run Terraform locally, it will create and manage a local state file (usually named `terraform.tfstate`).
   - This local state file will not include any resources created by the pipeline unless you explicitly import them into your local state.

### Implications

- **Destroying Resources**: 
  - If you attempt to run `terraform destroy` locally after resources have been created by the pipeline, Terraform will not be able to find those resources in your local state file. As a result, it will not be able to destroy them, leading to confusion and potential orphaned resources in your AWS account.
  
- **Improvement for a Future Version of this Project**:
  - If you plan to manage resources both locally and through a pipeline, we will have to consider using a remote backend for the Terraform state. This allows both environments to share the same state file, ensuring consistency.

---

# Log Service Infrastructure

This project demonstrates the use of AWS Lambda, API Gateway, and DynamoDB to build a serverless logging service. The infrastructure is defined using Terraform and is Optimized for the Free Tier.

---

## Architecture Overview

1. **DynamoDB**: A table to store log entries with a provisioned mode, ensuring operations fall within the Free Tier limits.
2. **Lambda Functions**: Two functions handle log operations:
   - **SaveLogFunction**: Saves incoming log data to the DynamoDB table.
   - **RetrieveLogsFunction**: Retrieves log data from the table.
3. **API Gateway**: Exposes the Lambda functions as HTTP endpoints for external applications to interact with the service.

---

## Infrastructure Components

### DynamoDB Table

The DynamoDB table `LogTable` is used to store logs. It is configured in **Provisioned mode** to utilize Free Tier limits. The table has the following attributes:

- **`ID` (String)**: Acts as the primary key for the table (auto-generated UUID)
- **`DateTime` (String)**: ISO format timestamp of when the log was created
- **`Severity` (String)**: Log severity level (defaults to "info")
- **`Message` (String)**: The actual log message content

---

### Lambda Functions

Two Lambda functions process log data:
- **SaveLogFunction**:
  - Accepts `POST /log` requests with log details.
  - Saves the data to `LogTable` in DynamoDB.
  - Uses a `save_log.zip` deployment package.

- **RetrieveLogsFunction**:
  - Accepts `GET /logs` requests to fetch the latest 100 logs from `LogTable` in JSON format, sorted by most recent.
  - Uses a `retrieve_logs.zip` deployment package.

**Common Configuration**:
- **Runtime**: Python 3.9
- **Environment Variables**:
  - `DYNAMODB_TABLE`: Name of the DynamoDB table.
- **Optimizations**:
  - Memory size: `128 MB`
  - Timeout: `5 seconds`

---

### API Gateway

An HTTP API Gateway provides endpoints for the Lambda functions:
- `POST /log`: Routes requests to `SaveLogFunction`.
- `GET /logs`: Routes requests to `RetrieveLogsFunction`.

---

### IAM Role and Policies

An IAM role is created for the Lambda functions with the following policies:
- **`AWSLambdaBasicExecutionRole`**: Allows basic Lambda execution.
- **`AmazonDynamoDBFullAccess`**: Grants full access to DynamoDB.

---