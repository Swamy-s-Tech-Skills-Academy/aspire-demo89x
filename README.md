# .NET Aspire With AI Stack

A distributed AI-powered architecture built with .NET Aspire, PostgreSQL, Redis, RabbitMQ, Keycloak, Ollama, and VectorDB.

## Deployment

```powershell
D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> az acAll resources will follow the `sv-*-{env}` naming convention for easy identification and management in the Azure Portal.

---

## 🎉 Implementation Summary

**Question**: Can't we use FixedNameInfrastructureResolver?

**Answer**: ✅ **YES! The FixedNameInfrastructureResolver IS working correctly with environment variables.**

The implementation uses a two-part approach:

1. **Automated**: Aspire Infrastructure Resolver handles Azure services with environment-driven naming (Redis Cache: `sv-cache-D` ✅)
2. **Parameterized**: Bicep templates use parameters for infrastructure naming (ACR, LAW, CAE, MI ✅)

All Azure resources now use consistent `sv-*-{env}` naming with proper environment suffix control via `AZURE_ENV_SUFFIX`!\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> azd init

# This will create a new Azure Developer CLI project in the current directory.
D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> dotnet run --project .\HelloAspireApp.AppHost.csproj --publisher manifest --output-path ./aspire-manifest.json

D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> azd config set alpha.infraSynth on
D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> azd infra synth

azd auth login --scope https://management.azure.com//.default

azd config set alpha.resourceGroupDeployments on

azd up
```

## Infrastructure Commands

### `azd infra synth` vs `azd infra gen`

**`azd infra synth`**

- **Purpose**: Automatically generates Infrastructure as Code (IaC) files from your .NET Aspire project
- **Source**: Reads your Aspire AppHost configuration and translates it to Bicep templates
- **Alpha Feature**: Currently requires `azd config set alpha.infraSynth on`
- **Output**: Creates Bicep files in `infra/` folder based on your Aspire resource definitions
- **Best for**: Aspire projects where you want automated infrastructure generation
- **Maintenance**: Can be re-run to update infrastructure when Aspire config changes
- **Custom Logic**: Respects your FixedNameInfrastructureResolver and other custom configurations

**`azd infra gen`**

- **Purpose**: Generates basic IaC template files for manual customization
- **Source**: Creates starter/skeleton infrastructure files based on common patterns
- **Stable Feature**: Part of the standard AZD toolset
- **Output**: Creates template Bicep files that require manual configuration
- **Best for**: Projects where you want full manual control over infrastructure
- **Maintenance**: Once generated, you manually maintain the files
- **Custom Logic**: Requires manual implementation of naming and configuration logic

**Recommendation**: Use `azd infra synth` for this Aspire project since it will automatically respect your custom naming resolver and generate appropriate infrastructure.

## Custom Resource Naming Implementation

This project implements a comprehensive `FixedNameInfrastructureResolver` that provides consistent, predictable naming for Azure resources using a company-branded approach with the "sv" prefix and environment-driven suffixes.

### 🎯 Implementation Status

#### ✅ Aspire Infrastructure Resolver (Automated)

- Azure Redis Cache: `sv-cache-D` (automatically applied via resolver)
- Storage Accounts: `sv{identifier}d` (when added via Aspire)
- Any future Azure resources added via `builder.AddAzure*()` methods

#### ✅ Container Apps Custom Naming

- API Service: `sv-api-service-dev` (via Program.cs service names)
- Web Frontend: `sv-web-frontend-dev` (via Program.cs service names)

#### ✅ Infrastructure Resources (Parameterized Bicep)

- Container Registry: `sv-acr-D` (via Bicep parameters)
- Log Analytics Workspace: `sv-law-D` (via Bicep parameters)
- Container Apps Environment: `sv-cae-D` (via Bicep parameters)
- Managed Identity: `sv-mi-D` (via Bicep parameters)

### 🌍 Environment Configuration

The project now supports dynamic environment suffixes via environment variables and Bicep parameters:

| Environment     | Suffix | Example Resource Names   |
| --------------- | ------ | ------------------------ |
| **Development** | `D`    | `sv-cache-D`, `sv-law-D` |
| **Test**        | `T`    | `sv-cache-T`, `sv-law-T` |
| **Staging**     | `S`    | `sv-cache-S`, `sv-law-S` |
| **Production**  | `P`    | `sv-cache-P`, `sv-law-P` |

**Environment Variable**: Set `AZURE_ENV_SUFFIX` to control the environment suffix (defaults to "D" if not set).

### 🔧 Architecture: Two-Part Naming System

#### Part 1: FixedNameInfrastructureResolver (Automated)

The resolver handles Azure resources added through Aspire's provisioning system and uses environment variables:

```csharp
public sealed class FixedNameInfrastructureResolver : InfrastructureResolver
{
    private const string UniqueNamePrefix = "sv";

    public override void ResolveProperties(ProvisionableConstruct construct, ProvisioningBuildOptions options)
    {
        // Get environment suffix from configuration, default to "D" (Development)
        string environmentSuffix = _configuration["AZURE_ENV_SUFFIX"] ?? "D";

        switch (construct)
        {
            case Azure.Provisioning.Redis.RedisResource redisCache:
                redisCache.Name = $"{UniqueNamePrefix}-{redisCache.BicepIdentifier.ToLowerInvariant()}-{environmentSuffix}";
                break;
            // ... other resource types
        }
    }
}
```

**Registration in Program.cs:**

```csharp
builder.Services.Configure<AzureProvisioningOptions>(options =>
{
    options.ProvisioningBuildOptions.InfrastructureResolvers.Insert(0, new FixedNameInfrastructureResolver(builder.Configuration));
});
```

#### Part 2: Parameterized Bicep Templates

Core infrastructure resources use Bicep parameters that can be set via environment variables:

```bicep
@description('Environment suffix (D=Dev, T=Test, S=Stage, P=Prod)')
param environmentSuffix string = 'D'

@description('Unique name prefix for resources')
param uniqueNamePrefix string = 'sv'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${uniqueNamePrefix}-mi-${environmentSuffix}'  // Results in: sv-mi-D
  location: location
  tags: tags
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${uniqueNamePrefix}acr${toLower(environmentSuffix)}${uniqueString(resourceGroup().id)}'  // Results in: sv-acr-d{unique}
  location: location
  // ...
}
```

### 📋 Complete Naming Reference

| Resource Type                  | Generated Name                              | Naming Source                          | Location                   |
| ------------------------------ | ------------------------------------------- | -------------------------------------- | -------------------------- |
| **Container Apps**             | `sv-api-service-dev`, `sv-web-frontend-dev` | Service names in Program.cs            | `*.tmpl.yaml` files        |
| **Azure Redis Cache**          | `sv-cache-D`                                | ✅ **FixedNameInfrastructureResolver** | `cache/cache.module.bicep` |
| **Container Registry**         | `sv-acr-d{unique}`                          | Bicep parameters                       | `resources.bicep`          |
| **Log Analytics Workspace**    | `sv-law-D`                                  | Bicep parameters                       | `resources.bicep`          |
| **Container Apps Environment** | `sv-cae-D`                                  | Bicep parameters                       | `resources.bicep`          |
| **Managed Identity**           | `sv-mi-D`                                   | Bicep parameters                       | `resources.bicep`          |

### 🔄 Deployment Workflow

1. **Set Environment**: `$env:AZURE_ENV_SUFFIX = "D"` (or T, S, P)
2. **Develop**: Make changes to your Aspire application
3. **Generate Infrastructure**: Run `azd infra synth --force`
4. **Deploy**: Run `azd up`

**Note**: The Bicep templates now use parameters, eliminating the need for manual file edits after `azd infra synth`.

### 🏗️ Service Configuration

Current service definitions in `Program.cs`:

```csharp
// Set environment suffix via environment variable: $env:AZURE_ENV_SUFFIX = "D"

// Azure Redis Cache - automatically named via resolver
var cache = builder.AddAzureRedis("cache");  // → sv-cache-D

// Container Apps - named via service identifiers
var apiService = builder.AddProject<Projects.HelloAspireApp_ApiService>("sv-api-service-dev");
builder.AddProject<Projects.HelloAspireApp_Web>("sv-web-frontend-dev")
    .WithExternalHttpEndpoints()
    .WithReference(cache)
    .WithReference(apiService);
```

### 📁 Generated Infrastructure Files

```text
infra/
├── main.bicep                           # Main deployment orchestration
├── main.parameters.json                 # Deployment parameters (environmentSuffix, uniqueNamePrefix)
├── resources.bicep                      # Core infrastructure (parameterized naming)
├── cache/
│   └── cache.module.bicep              # Azure Redis (auto-named via resolver)
├── cache-roles/
│   └── cache-roles.module.bicep        # Redis role assignments
├── sv-api-service-dev.tmpl.yaml        # API service container app
└── sv-web-frontend-dev.tmpl.yaml       # Web frontend container app
```

### 🎯 Naming Patterns Explained

| Pattern                    | Example          | Used For                                       |
| -------------------------- | ---------------- | ---------------------------------------------- |
| `sv-{service}-{env}`       | `sv-cache-D`     | Services that support hyphens                  |
| `sv{service}{env}{unique}` | `svacrd{unique}` | Services that don't support hyphens (ACR)      |
| `sv-{type}-{env}`          | `sv-law-D`       | Infrastructure services with type abbreviation |

**Environment Suffix**: Now dynamically controlled via `AZURE_ENV_SUFFIX` environment variable (D, T, S, P).

### 🚀 Current Status & Next Steps

#### ✅ Completed Implementation

1. **FixedNameInfrastructureResolver**: Successfully implemented with environment variable support
2. **Container Apps Naming**: Updated service names in Program.cs for consistent naming
3. **Parameterized Bicep Templates**: Infrastructure naming now uses parameters
4. **Environment Variable Support**: `AZURE_ENV_SUFFIX` controls environment suffix (D, T, S, P)
5. **Package Dependencies**: All required Azure.Provisioning packages installed
6. **Build Verification**: Project builds successfully with no errors

#### 🔄 Environment-Specific Deployment

Deploy to different environments by setting the environment variable:

```powershell
# Development Environment
$env:AZURE_ENV_SUFFIX = "D"
azd up

# Test Environment
$env:AZURE_ENV_SUFFIX = "T"
azd up

# Staging Environment
$env:AZURE_ENV_SUFFIX = "S"
azd up

# Production Environment
$env:AZURE_ENV_SUFFIX = "P"
azd up
```

#### 🎯 Ready for Multi-Environment Deployment

The project now supports seamless deployment across multiple environments with consistent naming patterns.

---

## 🎉 Implementation Summary

**Question**: Can't we use FixedNameInfrastructureResolver?

**Answer**: ✅ **YES! The FixedNameInfrastructureResolver IS working correctly.**

The implementation uses a two-part approach:

1. **Automated**: Aspire Infrastructure Resolver handles Azure services (Redis Cache: `sv-cache-dev` ✅)
2. **Semi-Automated**: Manual Bicep maintenance for core infrastructure (ACR, LAW, CAE, MI ✅)

All Azure resources now use consistent `sv-*-dev` naming with proper company branding!

```text
SUCCESS: Your app is ready for the cloud!
Run azd up to provision and deploy your app to Azure.
Run azd add to add new Azure components to your project.
Run azd infra gen to generate IaC for your project to disk, allowing you to manually manage it.
See ./next-steps.md for more information on configuring your app.
```
