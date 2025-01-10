# azure-pipelines.yml

# Trigger the pipeline on changes to the main branch
trigger:
  branches:
    include:
      - main  # Adjust this to your branch

# Use the latest Ubuntu VM image
pool:
  vmImage: 'ubuntu-latest'

# Define build and deployment stages
stages:
  - stage: LoginToACR
    displayName: 'Login to Azure Container Registry'
    jobs:
      - job: LoginACR
        displayName: 'Login to ACR'
        steps:
          - script: |
              echo "${ACR_PASSWORD}" | docker login "${ACR_LOGIN_SERVER}" --username "${ACR_USERNAME}" --password-stdin
            displayName: 'Login to ACR'

  - stage: BuildDockerImage
    displayName: 'Build Docker Image'
    jobs:
      - job: BuildDocker
        displayName: 'Build Docker Image'
        steps:
          - script: |
              docker build -t $ACR_NAME/$DOCKER_IMAGE_NAME:latest .
            displayName: 'Build Docker Image'

  - stage: ListDockerImages
    displayName: 'List Docker Images'
    jobs:
      - job: ListImages
        displayName: 'List Docker Images'
        steps:
          - script: |
              docker images
            displayName: 'List Docker Images'

  - stage: TagDockerImage
    displayName: 'Tag Docker Image'
    jobs:
      - job: TagImage
        displayName: 'Tag Docker Image'
        steps:
          - script: |
              docker tag $ACR_NAME/$DOCKER_IMAGE_NAME:latest $ACR_LOGIN_SERVER/$DOCKER_IMAGE_NAME:latest
            displayName: 'Tag Docker Image'

  - stage: PushDockerImage
    displayName: 'Push Docker Image to ACR'
    jobs:
      - job: PushImage
        displayName: 'Push Docker Image to ACR'
        steps:
          - script: |
              docker push $ACR_LOGIN_SERVER/$DOCKER_IMAGE_NAME:latest
            displayName: 'Push Docker Image'

  - stage: DeployToAzure
    displayName: 'Deploy to Azure'
    jobs:
      - job: DeployInfrastructure
        displayName: 'Provision and Deploy Infrastructure'
        timeoutInMinutes: 120  # Set job timeout to 120 minutes
        steps:
          # Checkout code
          - checkout: self

          # Install Terraform
          - script: |
              curl -o terraform.zip https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip
              unzip terraform.zip
              sudo mv terraform /usr/local/bin/
              terraform -version
            displayName: 'Install Terraform'

          # Authenticate with Azure and run Terraform commands
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Abel-serviceP-conn'  # Azure DevOps service connection
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                # Enable Terraform debug logging
                export TF_LOG=DEBUG
                export TF_LOG_PATH="terraform_debug.log"  # Specify a log file

                # Set the required Terraform variables as environment variables
                export TF_VAR_client_id=$(ARM_CLIENT_ID)
                export TF_VAR_client_secret=$(ARM_CLIENT_SECRET)
                export TF_VAR_tenant_id=$(ARM_TENANT_ID)
                export TF_VAR_subscription_id=$(ARM_SUBSCRIPTION_ID)

                # Initialize and apply Terraform
                terraform init | tee -a $TF_LOG_PATH
                terraform plan -target=module.Create_App_Service | tee -a $TF_LOG_PATH
                terraform apply -target=module.Create_App_Service -auto-approve | tee -a $TF_LOG_PATH
            displayName: 'Provision Infrastructure with Terraform'

          # Configure Azure Web App with Docker Image
          - script: |
              az webapp config container set --name $AZURE_WEB_APP_NAME \
              --resource-group $AZURE_RESOURCE_GROUP \
              --docker-custom-image-name $ACR_LOGIN_SERVER/$DOCKER_IMAGE_NAME:latest \
              --docker-registry-server-url https://$ACR_LOGIN_SERVER \
              --docker-registry-server-user $ACR_USERNAME \
              --docker-registry-server-password $ACR_PASSWORD
            displayName: 'Configure Azure Web App'
