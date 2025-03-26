#!/bin/bash

# Azure configuration
RESOURCE_GROUP="abel-bot-rg"
LOCATION="eastus"
WEBAPP_NAME="abel-bot"
CONTAINER_REGISTRY_NAME="abelbotregistry"
CONTAINER_REGISTRY_SKU="Basic"
APP_SERVICE_PLAN="abel-bot-plan"
APP_SERVICE_SKU="B1"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY_NAME \
    --sku $CONTAINER_REGISTRY_SKU \
    --admin-enabled true

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY_NAME --query "passwords[0].value" -o tsv)

# Create App Service Plan
az appservice plan create --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku $APP_SERVICE_SKU \
    --is-linux

# Create Web App for Containers
az webapp create --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --name $WEBAPP_NAME \
    --deployment-container-image-name "$CONTAINER_REGISTRY_NAME.azurecr.io/abel-bot:latest"

# Configure Web App to use ACR
az webapp config container set --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name "$CONTAINER_REGISTRY_NAME.azurecr.io/abel-bot:latest" \
    --docker-registry-server-url "https://$CONTAINER_REGISTRY_NAME.azurecr.io" \
    --docker-registry-server-user $ACR_USERNAME \
    --docker-registry-server-password $ACR_PASSWORD

# Create Azure Key Vault
az keyvault create --name "abel-bot-kv" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

# Store MT5 credentials in Key Vault
az keyvault secret set --vault-name "abel-bot-kv" \
    --name "MT5-LOGIN" \
    --value "5034098728"

az keyvault secret set --vault-name "abel-bot-kv" \
    --name "MT5-PASSWORD" \
    --value "*gG8PrXx"

az keyvault secret set --vault-name "abel-bot-kv" \
    --name "MT5-SERVER" \
    --value "MetaQuotes-Demo"

# Get Key Vault URL
KEY_VAULT_URL=$(az keyvault show --name "abel-bot-kv" --resource-group $RESOURCE_GROUP --query properties.vaultUri -o tsv)

# Configure Web App environment variables
az webapp config appsettings set --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings KEY_VAULT_URL=$KEY_VAULT_URL

# Build and push Docker image
az acr build --registry $CONTAINER_REGISTRY_NAME \
    --image abel-bot:latest \
    .

# Restart Web App to apply changes
az webapp restart --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP

echo "Deployment complete! Web App URL: https://$WEBAPP_NAME.azurewebsites.net" 