# Infrastructure as Code (IaC) Guide

This document provides a comprehensive guide to the Infrastructure as Code implementation in the aspire-demo89x project using Bicep templates and Azure Developer CLI.

## 🏗️ Overview

The project uses **Bicep** templates for infrastructure definition and **Azure Developer CLI (azd)** for deployment orchestration. This approach provides:

- **Declarative Infrastructure**: Define what you want, not how to get it
- **Version Control**: Track infrastructure changes alongside application code
- **Repeatability**: Consistent deployments across environments
- **Validation**: Pre-deployment infrastructure validation
- **Automation**: Integrated CI/CD pipeline deployment

## 📁 Infrastructure Structure

### Directory Layout

```
src/HelloAspireApp.AppHost/
├── infra/                          # Infrastructure as Code
│   ├── main.bicep                  # Main orchestration template
│   ├── main.parameters.json        # Parameter mapping
│   ├── resources.bicep             # Core Azure resources
│   ├── cache/
│   │   └── cache.module.bicep      # Redis cache module
│   └── cache-roles/
│       └── cache-roles.module.bicep # Cache role assignments
├── azure.yaml                      # Azure Developer CLI configuration
├── Program.cs                      # Application host
└── HelloAspireApp.AppHost.csproj   # Project file
```

### Template Hierarchy

```
main.bicep (Subscription scope)
├── Resource Group Creation
├── resources.bicep (Resource Group scope)
│   ├── Managed Identity
│   ├── Container Registry
│   ├── Log Analytics Workspace
│   └── Container Apps Environment
├── cache.module.bicep (Resource Group scope)
│   └── Redis Cache
└── cache-roles.module.bicep (Resource Group scope)
    └── Role Assignments
```

## 🎯 Main Template (main.bicep)

### Purpose

The main template orchestrates all infrastructure components at the subscription level.

### Key Features

- **Subscription Scope**: Manages resource groups
- **Region Mapping**: Converts Azure regions to abbreviations
- **Parameter Validation**: Ensures valid inputs
- **Resource Orchestration**: Coordinates module deployment

### Template Structure

```bicep
targetScope = 'subscription'

// Parameters
@minLength(1)
@maxLength(64)
@description('Name of the environment')
param environmentName string

@minLength(1)
@description('The location used for all deployed resources')
param location string

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

@description('Resource group name override (optional)')
param resourceGroupName string = ''

// Region abbreviation mapping
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

// Resource Group
var actualResourceGroupName = !empty(resourceGroupName) ? resourceGroupName : 'rg-${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: actualResourceGroupName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
}

// Module deployments
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
```

### Parameter Configuration

The `main.parameters.json` file maps environment variables to template parameters:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "${AZURE_ENV_NAME}"
    },
    "location": {
      "value": "${AZURE_LOCATION}"
    },
    "environmentSuffix": {
      "value": "${AZURE_ENV_SUFFIX}"
    },
    "resourceGroupName": {
      "value": "${AZURE_RESOURCE_GROUP}"
    }
  }
}
```

## 🔧 Core Resources (resources.bicep)

### Purpose

Defines the core Azure resources required for the application.

### Resources Created

1. **Managed Identity**

   - User-assigned managed identity for service authentication
   - Name: `sv-mi-{environmentSuffix}-{regionAbbreviation}`

2. **Container Registry**

   - Stores Docker images for the application
   - Name: `svacr{environmentSuffix}{regionAbbreviation}`

3. **Log Analytics Workspace**

   - Centralized logging and monitoring
   - Name: `sv-law-{environmentSuffix}-{regionAbbreviation}`

4. **Container Apps Environment**
   - Hosting environment for containerized applications
   - Name: `sv-cae-{environmentSuffix}-{regionAbbreviation}`

### Key Implementation Details

```bicep
@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

@description('Region abbreviation for resource naming')
param regionAbbreviation string

@description('Tags that will be applied to all resources')
param tags object = {}

// Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'sv-mi-${environmentSuffix}-${regionAbbreviation}'
  location: location
  tags: tags
}

// Container Registry with ACR Pull role assignment
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'svacr${toLower(environmentSuffix)}${regionAbbreviation}'
  location: location
  sku: {
    name: 'Basic'
  }
  tags: tags
}

// Role assignment for managed identity to pull from ACR
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
```

## 🗄️ Cache Module (cache.module.bicep)

### Purpose

Manages Redis cache deployment with proper configuration.

### Features

- **Environment-specific naming**: Follows naming convention
- **Performance optimization**: Basic tier for development, Standard for production
- **Network configuration**: Proper subnet and firewall settings
- **Monitoring integration**: Connected to Log Analytics

### Implementation

```bicep
@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

@description('Region abbreviation for resource naming')
param regionAbbreviation string

resource cache 'Microsoft.Cache/redis@2023-08-01' = {
  name: 'sv-cache-${environmentSuffix}-${regionAbbreviation}'
  location: location
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 0
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
  tags: tags
}

output connectionString string = '${cache.properties.hostName}:${cache.properties.sslPort},password=${cache.listKeys().primaryKey},ssl=True,abortConnect=False'
```

## 🔐 Role Assignments (cache-roles.module.bicep)

### Purpose

Manages RBAC role assignments for cache access.

### Features

- **Principle of least privilege**: Only necessary permissions
- **Managed identity integration**: Uses managed identity for authentication
- **Environment-specific**: Scoped to specific environment resources

### Implementation

```bicep
@description('Principal ID of the managed identity')
param principalId string

@description('Principal name of the managed identity')
param principalName string

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

@description('Region abbreviation for resource naming')
param regionAbbreviation string

// Reference to the cache resource
resource cache 'Microsoft.Cache/redis@2023-08-01' existing = {
  name: 'sv-cache-${environmentSuffix}-${regionAbbreviation}'
}

// Redis Cache Contributor role assignment
resource cacheContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cache.id, principalId, 'e0f68234-74aa-48ed-9826-c38b57376e17')
  scope: cache
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e0f68234-74aa-48ed-9826-c38b57376e17')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
```

## 🚀 Azure Developer CLI Integration

### Configuration File (azure.yaml)

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/Azure/azure-dev/main/schemas/v1.0/azure.yaml.json

name: helloaspireapp-apphost
services:
  app:
    language: dotnet
    project: ./HelloAspireApp.AppHost.csproj
    host: containerapp
```

### Key Features

- **Service Definition**: Defines the .NET Aspire service
- **Container Apps Integration**: Automatically deploys to Container Apps
- **Build and Deploy**: Handles both infrastructure and application deployment

### Common Commands

```bash
# Initialize new environment
azd env new <environment-name>

# Set environment variables
azd env set AZURE_LOCATION eastus
azd env set AZURE_ENV_SUFFIX D
azd env set AZURE_RESOURCE_GROUP rg-Dev-eastus

# Provision infrastructure only
azd provision

# Deploy application only
azd deploy

# Provision and deploy together
azd up

# View deployment status
azd show

# Clean up resources
azd down
```

## 🔧 Environment Configuration

### Environment Variables

The infrastructure relies on these environment variables:

| Variable                | Description              | Example             |
| ----------------------- | ------------------------ | ------------------- |
| `AZURE_ENV_NAME`        | Environment name for azd | `aspire-dev-001`    |
| `AZURE_LOCATION`        | Azure region             | `eastus`            |
| `AZURE_ENV_SUFFIX`      | Environment suffix       | `D`                 |
| `AZURE_RESOURCE_GROUP`  | Resource group name      | `rg-Dev-eastus`     |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID    | `12345678-1234-...` |
| `AZURE_TENANT_ID`       | Azure tenant ID          | `87654321-4321-...` |

### Setting Environment Variables

```bash
# For local development
azd env set AZURE_ENV_NAME aspire-dev-001
azd env set AZURE_LOCATION eastus
azd env set AZURE_ENV_SUFFIX D
azd env set AZURE_RESOURCE_GROUP rg-Dev-eastus

# For CI/CD (GitHub Actions)
# Set as GitHub Environment Variables in repository settings
```

## 🧪 Testing and Validation

### Pre-deployment Validation

```bash
# Validate Bicep templates
az bicep build --file infra/main.bicep

# Preview infrastructure changes
azd provision --preview

# Validate template deployment
az deployment sub validate \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Post-deployment Verification

```bash
# Check deployment status
azd show

# View resource groups
az group list --query "[?contains(name, 'rg-')]"

# Check specific resources
az resource list --resource-group rg-Dev-eastus
```

## 🔄 CI/CD Integration

### GitHub Actions Integration

The infrastructure is deployed through GitHub Actions workflows:

```yaml
# Provision infrastructure
- name: Provision Infrastructure
  run: azd provision --no-prompt

# Deploy application
- name: Deploy Application
  run: azd deploy --no-prompt
```

### Pipeline Features

- **Automated validation**: Bicep template validation
- **Environment-specific deployment**: Based on GitHub Environments
- **Rollback capabilities**: Infrastructure versioning
- **Health checks**: Post-deployment verification

## 📊 Monitoring and Diagnostics

### Infrastructure Monitoring

- **Azure Monitor**: Resource health and performance
- **Log Analytics**: Centralized logging
- **Application Insights**: Application performance monitoring
- **Azure Alerts**: Proactive notifications

### Diagnostic Commands

```bash
# Check infrastructure health
azd show --output json | jq '.services'

# View logs
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | limit 100"

# Check resource status
az resource show \
  --resource-group rg-Dev-eastus \
  --name sv-mi-D-use \
  --resource-type Microsoft.ManagedIdentity/userAssignedIdentities
```

## 📚 Best Practices

### Template Design

1. **Modular approach**: Separate concerns into modules
2. **Parameter validation**: Use decorators for input validation
3. **Resource dependencies**: Explicit dependency management
4. **Output consistency**: Provide necessary outputs for integration
5. **Documentation**: Comment complex logic

### Security Considerations

1. **Managed Identity**: Use managed identity for authentication
2. **RBAC**: Implement role-based access control
3. **Network security**: Configure proper network boundaries
4. **Secrets management**: Use Azure Key Vault for secrets
5. **Compliance**: Follow organizational security policies

### Deployment Strategies

1. **Environment parity**: Keep environments as similar as possible
2. **Infrastructure versioning**: Track infrastructure changes
3. **Rollback planning**: Prepare rollback procedures
4. **Testing**: Validate in non-production environments first
5. **Monitoring**: Implement comprehensive monitoring

## 🐛 Troubleshooting

### Common Issues

1. **Naming conflicts**: Ensure unique resource names
2. **Permission issues**: Check RBAC assignments
3. **Region availability**: Verify service availability in target region
4. **Quota limits**: Check subscription quotas
5. **Template errors**: Validate Bicep syntax

### Debugging Steps

1. **Check azd logs**: `azd show --output json`
2. **Validate templates**: `az bicep build`
3. **Review ARM deployment**: Check Azure portal deployment history
4. **Test connectivity**: Verify network connectivity
5. **Check resource status**: Use Azure CLI or portal

---

_This IaC implementation provides a robust, scalable, and maintainable infrastructure foundation for the aspire-demo89x project._
