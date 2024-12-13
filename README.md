# ggl-simple-api - a simple API to save and retrieve logs

To run the Terraform code locally:
1.	Prerequisites:
    o	Install Terraform.
    o	Install AWS CLI.
    o	Configure AWS CLI with credentials using aws configure.

2.	Prepare the Lambda Functions:
    o	Zip the two python files found in the root directory function file individually:
        #bash
        zip save_log.zip save_log.py
        zip retrieve_logs.zip retrieve_logs.py

3.	Deploy the Solution:
    o	Clone or copy the Terraform code into a directory.
    o	Place the save_log.zip and retrieve_logs.zip files in the same directory as the Terraform script.
    o	Initialize the Terraform environment:
        #bash
        terraform init
    o	Plan the deployment:
        #bash
        terraform plan
    o	Apply the deployment:
        #bash
        terraform apply
    o	Once deployed, Terraform will output the API endpoint URL.

4.	Test the API:
    o	Use curl or a REST client (e.g., Postman) to interact with the API:
    o	Save a Log:
        #bash
        curl -X POST -H "Content-Type: application/json" -d '{"ID": "123", "message": "Test log"}' <API_ENDPOINT>/log
    o	Retrieve Logs:
        #bash
        curl -X GET <API_ENDPOINT>/logs

5.	Clean Up:
    o	To avoid incurring charges, destroy the infrastructure:
        #bash
        terraform destroy

Pipeline Overview:

The GitHub Actions workflow will:

1.	Set up Terraform in the pipeline environment.
2.	Authenticate with AWS.
3.	Initialize the Terraform backend.
4.	Plan the infrastructure deployment.
5.	Apply the changes to deploy the infrastructure.

Prerequisites

1.	AWS Account:
    o	An AWS account with access to the Free Tier.

2.	Terraform State Storage:
    o	The code will use Terraform's default state in the repository.

3.	GitHub Secrets:
    o	Add the following secrets to your repository in Settings > Secrets and variables > Actions > New repository secret:
    o	AWS_SECRET_ACCESS_KEY: Your AWS secret key.
    o	AWS_REGION: Your AWS region (e.g., us-east-1).

Folder Structure

Ensure the repository has the following structure:
├── save_log.zip	 	# Python code
├── retrieve_logs.zip	# Python code
├── main.tf                	# Terraform configuration file
├── .github/
│   └── workflows/
│       └── deploy.yml     	# GitHub Actions workflow file

How to Run the Pipeline
1.	Commit Changes:
    o	Commit your artifacts folder, Terraform files, and the GitHub Actions workflow to the main branch:
        #bash
        git add .
        git commit -m "Add pipeline for deploying log service"
        git push origin main

2.	Trigger the Workflow:
    o	The pipeline will automatically run when changes are pushed to the main branch.

3.	Monitor Progress:
    o	Go to Actions in your GitHub repository to monitor the pipeline's progress.
    o	Check logs for steps like Terraform Init, Terraform Plan, and Terraform Apply.

Testing the API
After the deployment pipeline completes:

1.	API Gateway Endpoint:
    o	The api_endpoint output will be displayed in the Terraform Apply logs.
    o	Use it to test the API as described earlier.
2.	Test the Lambda Functions:
    o	Follow the API testing steps using curl or Postman.

Rollback
To destroy the deployed infrastructure, run the following command locally or modify the pipeline to include a terraform destroy job:
#bash
terraform destroy -auto-approve
