# Resource Naming Convention

This document defines the enterprise-grade Azure resource naming convention used in the aspire-demo89x project.

## 🏷️ Naming Strategy

### Core Principles

1. **Consistency**: All resources follow the same naming pattern
2. **Environment Awareness**: Clear identification of deployment environment
3. **Region Specific**: Resources include region abbreviations for multi-region deployments
4. **Service Context**: Names reflect the service purpose and function
5. **Compliance**: Adheres to Azure naming restrictions and best practices

### Naming Pattern

```
{service-prefix}-{resource-type}-{environment}-{region}
```

**Components:**

- **service-prefix**: `sv` (Service Prefix)
- **resource-type**: Abbreviated resource type (mi, law, cache, etc.)
- **environment**: Single letter environment code (D/T/S/P)
- **region**: Azure region abbreviation (use, usc, etc.)

## 🌍 Region Abbreviations

### Supported Regions

| Azure Region     | Abbreviation | Example Usage  |
| ---------------- | ------------ | -------------- |
| East US          | `use`        | `sv-mi-D-use`  |
| Central US       | `usc`        | `sv-mi-D-usc`  |
| West US          | `usw`        | `sv-mi-D-usw`  |
| West US 2        | `usw2`       | `sv-mi-D-usw2` |
| East US 2        | `use2`       | `sv-mi-D-use2` |
| South Central US | `ussc`       | `sv-mi-D-ussc` |
| North Central US | `usnc`       | `sv-mi-D-usnc` |
| West Central US  | `uswc`       | `sv-mi-D-uswc` |

### Adding New Regions

To add support for new regions, update the `regionAbbreviations` object in `infra/main.bicep`:

```bicep
var regionAbbreviations = {
  eastus: 'use'
  centralus: 'usc'
  westus: 'usw'
  // Add new regions here
  westeurope: 'weu'
  northeurope: 'neu'
}
```

## 🔤 Environment Codes

### Standard Environment Codes

| Environment | Code | Description             | Example Resource |
| ----------- | ---- | ----------------------- | ---------------- |
| Development | `D`  | Development environment | `sv-mi-D-use`    |
| Test        | `T`  | Testing environment     | `sv-mi-T-use`    |
| Staging     | `S`  | Staging/UAT environment | `sv-mi-S-use`    |
| Production  | `P`  | Production environment  | `sv-mi-P-use`    |

### Custom Environment Codes

For custom environments, use descriptive single letters:

- `I` - Integration
- `Q` - QA
- `U` - User Acceptance Testing
- `B` - Beta/Preview

## 🛠️ Resource Type Abbreviations

### Core Resources

| Resource Type              | Abbreviation | Example          |
| -------------------------- | ------------ | ---------------- |
| Managed Identity           | `mi`         | `sv-mi-D-use`    |
| Log Analytics Workspace    | `law`        | `sv-law-D-use`   |
| Container Apps Environment | `cae`        | `sv-cae-D-use`   |
| Redis Cache                | `cache`      | `sv-cache-D-use` |

### Container Registry

Container Registry follows a slightly different pattern due to naming restrictions:

```
svacr{environment}{region}
```

Examples:

- Development East US: `svacrduse`
- Test East US: `svacrtuse`
- Production Central US: `svacrpusc`

## 📋 Complete Resource Naming Reference

### Development Environment (Multi-Region)

**East US:**

```yaml
Resource Group: rg-Dev-eastus
Managed Identity: sv-mi-D-use
Container Registry: svacrduse
Log Analytics Workspace: sv-law-D-use
Container Apps Environment: sv-cae-D-use
Redis Cache: sv-cache-D-use
```

**Central US:**

```yaml
Resource Group: rg-Dev-centralus
Managed Identity: sv-mi-D-usc
Container Registry: svacrdusc
Log Analytics Workspace: sv-law-D-usc
Container Apps Environment: sv-cae-D-usc
Redis Cache: sv-cache-D-usc
```

### Test Environment (East US)

```yaml
Resource Group: rg-Test-eastus
Managed Identity: sv-mi-T-use
Container Registry: svacrtuse
Log Analytics Workspace: sv-law-T-use
Container Apps Environment: sv-cae-T-use
Redis Cache: sv-cache-T-use
```

### Production Environment (Central US)

```yaml
Resource Group: rg-Production-centralus
Managed Identity: sv-mi-P-usc
Container Registry: svacrpusc
Log Analytics Workspace: sv-law-P-usc
Container Apps Environment: sv-cae-P-usc
Redis Cache: sv-cache-P-usc
```

## 🔧 Implementation Details

### Bicep Template Configuration

The naming convention is implemented in `infra/main.bicep`:

```bicep
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
```

### Parameter Configuration

Resources receive naming parameters:

```bicep
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

### Resource Implementation

Individual resources use the naming pattern:

```bicep
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'sv-mi-${environmentSuffix}-${regionAbbreviation}'
  location: location
  tags: tags
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'sv-law-${environmentSuffix}-${regionAbbreviation}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: tags
}
```

## 🎯 Benefits

### Operational Benefits

1. **Easy Identification**: Quickly identify environment and region
2. **Consistent Naming**: Reduces confusion and errors
3. **Automation Friendly**: Programmatic resource discovery
4. **Compliance**: Meets enterprise naming standards

### Management Benefits

1. **Cost Tracking**: Group resources by environment/region
2. **Security Policies**: Apply policies based on naming patterns
3. **Monitoring**: Filter and group resources logically
4. **Disaster Recovery**: Identify region-specific resources

### Development Benefits

1. **Environment Isolation**: Clear separation between environments
2. **Multi-Region Support**: Scalable across regions
3. **Debugging**: Easier troubleshooting with clear names
4. **Documentation**: Self-documenting infrastructure

## 🔍 Validation

### Naming Validation Rules

1. **Length Limits**: All names must respect Azure service limits
2. **Character Restrictions**: Only alphanumeric characters and hyphens
3. **Case Sensitivity**: Consistent lowercase for most resources
4. **Uniqueness**: Names must be unique within their scope

### Validation Process

The naming convention is validated during:

1. **Bicep Compilation**: Template validation
2. **CI/CD Pipeline**: Automated naming checks
3. **Deployment**: Azure resource validation
4. **Post-Deployment**: Resource naming verification

## 📚 Best Practices

### Do's

✅ Use the standard naming pattern consistently
✅ Include environment and region in all resource names
✅ Use approved abbreviations from this document
✅ Validate names before deployment
✅ Document any custom naming decisions

### Don'ts

❌ Don't use special characters beyond hyphens
❌ Don't exceed Azure service naming limits
❌ Don't use ambiguous abbreviations
❌ Don't mix naming conventions
❌ Don't hardcode resource names in application code

## 🔄 Migration Guide

### Updating Existing Resources

When updating existing resources to use the new naming convention:

1. **Plan**: Identify all affected resources
2. **Backup**: Create backups of critical data
3. **Update**: Apply new naming in Bicep templates
4. **Test**: Validate in non-production environments
5. **Deploy**: Roll out to production with proper monitoring

### Rollback Strategy

If rollback is needed:

1. Keep old resource names as comments in Bicep
2. Maintain environment variable mapping
3. Test rollback procedures in development
4. Document rollback steps

---

_This naming convention ensures consistency, scalability, and maintainability across all Azure resources in the aspire-demo89x project._
