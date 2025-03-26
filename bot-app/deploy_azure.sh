#!/bin/bash

# Azure configuration
RESOURCE_GROUP="trading-bot-rg"
LOCATION="eastus"
CONTAINER_APP_NAME="trading-bot"
CONTAINER_REGISTRY_NAME="tradingbotregistry"
CONTAINER_REGISTRY_SKU="Basic"

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

# Create Azure Key Vault
az keyvault create --name "trading-bot-kv" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

# Store MT5 credentials in Key Vault
az keyvault secret set --vault-name "trading-bot-kv" \
    --name "MT5-LOGIN" \
    --value "5034098728"

az keyvault secret set --vault-name "trading-bot-kv" \
    --name "MT5-PASSWORD" \
    --value "*gG8PrXx"

az keyvault secret set --vault-name "trading-bot-kv" \
    --name "MT5-SERVER" \
    --value "MetaQuotes-Demo"

# Build and push Docker image
az acr build --registry $CONTAINER_REGISTRY_NAME \
    --image trading-bot:latest \
    .

# Create Container App
az containerapp create \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --environment "trading-bot-env" \
    --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --target-port 80 \
    --ingress external \
    --query properties.configuration.ingress.fqdn 