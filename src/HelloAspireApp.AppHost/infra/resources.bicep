@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

@description('Region abbreviation for resource naming (use/usc/etc)')
param regionAbbreviation string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Resource ID of an existing Log Analytics workspace to use')
param existingLogAnalyticsWorkspaceId string = ''

@description('Customer ID of the existing Log Analytics workspace')
param existingLogAnalyticsWorkspaceCustomerId string = ''

@description('Primary shared key of the existing Log Analytics workspace')
param existingLogAnalyticsWorkspaceSharedKey string = ''

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'sv-mi-${environmentSuffix}-${regionAbbreviation}'
  location: location
  tags: tags
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'svacr${toLower(environmentSuffix)}${regionAbbreviation}'
  location: location
  sku: {
    name: 'Basic'
  }
  tags: tags
}

resource caeMiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    containerRegistry.id,
    managedIdentity.id,
    subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  )
  scope: containerRegistry
  properties: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
  }
}

// Create Log Analytics workspace only if an existing one is not provided
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (empty(existingLogAnalyticsWorkspaceId)) {
  name: 'sv-law-${environmentSuffix}-${regionAbbreviation}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
  tags: tags
}

// Get reference to existing Log Analytics workspace if ID is provided
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!empty(existingLogAnalyticsWorkspaceId)) {
  name: last(split(existingLogAnalyticsWorkspaceId, '/'))
  scope: resourceGroup(split(existingLogAnalyticsWorkspaceId, '/')[2], split(existingLogAnalyticsWorkspaceId, '/')[4])
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-02-02-preview' = {
  name: 'sv-cae-${environmentSuffix}-${regionAbbreviation}'
  location: location
  properties: {
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'consumption'
      }
    ]
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: !empty(existingLogAnalyticsWorkspaceId)
          ? existingLogAnalyticsWorkspaceCustomerId
          : logAnalyticsWorkspace.properties.customerId
        sharedKey: !empty(existingLogAnalyticsWorkspaceId)
          ? existingLogAnalyticsWorkspaceSharedKey
          : logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
  tags: tags

  resource aspireDashboard 'dotNetComponents' = {
    name: 'aspire-dashboard'
    properties: {
      componentType: 'AspireDashboard'
    }
  }
}

output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.properties.clientId
output MANAGED_IDENTITY_NAME string = managedIdentity.name
output MANAGED_IDENTITY_PRINCIPAL_ID string = managedIdentity.properties.principalId
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = !empty(existingLogAnalyticsWorkspaceId)
  ? last(split(existingLogAnalyticsWorkspaceId, '/'))
  : logAnalyticsWorkspace.name
output AZURE_LOG_ANALYTICS_WORKSPACE_ID string = !empty(existingLogAnalyticsWorkspaceId)
  ? existingLogAnalyticsWorkspaceId
  : logAnalyticsWorkspace.id
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID string = managedIdentity.id
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppEnvironment.name
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppEnvironment.id
output AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN string = containerAppEnvironment.properties.defaultDomain
