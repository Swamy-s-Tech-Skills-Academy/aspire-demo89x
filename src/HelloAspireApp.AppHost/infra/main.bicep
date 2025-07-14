targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention, the name of the resource group for your application will use this name, prefixed with rg-')
param environmentName string

@minLength(1)
@description('The location used for all deployed resources')
param location string

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

@description('Resource group name override (optional)')
param resourceGroupName string = ''

// Function to convert Azure location to region abbreviation
var regionAbbreviations = {
  eastus: 'use'
  centralus: 'usc'
  westus: 'usw'
  westus2: 'usw2'
  eastus2: 'use2'
  southcentralus: 'ussc'
  northcentralus: 'usnc'
  westcentralus: 'uswc'
}

var regionAbbreviation = regionAbbreviations[?location] ?? 'unk'

var tags = {
  'azd-env-name': environmentName
}

// Use resourceGroupName if provided, otherwise fall back to default naming
var actualResourceGroupName = !empty(resourceGroupName) ? resourceGroupName : 'rg-${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: actualResourceGroupName
  location: location
  tags: tags
}
module resources 'resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    location: location
    tags: tags
    environmentSuffix: environmentSuffix
    regionAbbreviation: regionAbbreviation
  }
}

module cache 'cache/cache.module.bicep' = {
  name: 'cache'
  scope: rg
  params: {
    location: location
    environmentSuffix: environmentSuffix
    regionAbbreviation: regionAbbreviation
  }
}
module cache_roles 'cache-roles/cache-roles.module.bicep' = {
  name: 'cache-roles'
  scope: rg
  params: {
    principalId: resources.outputs.MANAGED_IDENTITY_PRINCIPAL_ID
    principalName: resources.outputs.MANAGED_IDENTITY_NAME
    environmentSuffix: environmentSuffix
    regionAbbreviation: regionAbbreviation
  }
}

output MANAGED_IDENTITY_CLIENT_ID string = resources.outputs.MANAGED_IDENTITY_CLIENT_ID
output MANAGED_IDENTITY_NAME string = resources.outputs.MANAGED_IDENTITY_NAME
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = resources.outputs.AZURE_LOG_ANALYTICS_WORKSPACE_NAME
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID string = resources.outputs.AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = resources.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_NAME
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = resources.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_ID
output AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN string = resources.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN
output CACHE_CONNECTIONSTRING string = cache.outputs.connectionString
