# .NET Aspire With Custom Azure Resource Naming

A .NET Aspire project implementing enterprise-grade Azure resource naming conventions with automated infrastructure generation, custom naming enforcement, and full CI/CD integration.

## 🚀 Quick Start - Automated Deployment

### Local Development

Navigate to the AppHost directory and run the deployment script:

```powershell
# Navigate to the AppHost directory
cd src\HelloAspireApp.AppHost

# Deploy to Development environment (default)
.\Deploy-WithCustomNames.ps1

# Deploy to other environments
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "P"  # Production
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "T"  # Test
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "S"  # Staging

# Then deploy to Azure
azd up
```

### GitHub Actions CI/CD

Set up GitHub Environments (`Dev`, `Test`) with the required variables and trigger deployments through GitHub Actions workflows. See [GitHub Environments Setup Guide](docs/github-environments-setup.md) for detailed instructions.

All resources will follow the `sv-*-{env}` naming convention for easy identification and management in the Azure Portal.

---

## 🏗️ Dynamic Azure Resource Naming Solution

This project implements a comprehensive, **fully automated** and **parameter-driven** custom naming convention for Azure resources that addresses the challenges of maintaining consistent naming across environments when using .NET Aspire and Azure Developer CLI (azd).

### 🎯 Problem Statement

When using `azd infra generate` (or `azd infra synth`) with .NET Aspire:

- Azure resources get auto-generated names with random suffixes (e.g., `acr-abc123xyz`)
- Manual edits to Bicep files are overwritten each time infrastructure is regenerated
- Maintaining consistent naming conventions across environments becomes challenging
- Enterprise naming standards are difficult to enforce automatically
- CI/CD pipelines need dynamic environment-specific naming

### ✅ Solution: Dynamic Parameter-Based Approach

The solution has evolved from a script-based approach to a **dynamic parameter-driven system** that works seamlessly with both local development and CI/CD pipelines.

#### Part 1: FixedNameInfrastructureResolver (Aspire Resources)

Handles Azure resources added through Aspire's builder pattern (e.g., `builder.AddAzureRedis()`):

```csharp
public sealed class FixedNameInfrastructureResolver : InfrastructureResolver
{
    private const string UniqueNamePrefix = "sv";
    private readonly IConfiguration _configuration;

    public override void ResolveProperties(ProvisionableConstruct construct, ProvisioningBuildOptions options)
    {
        string environmentSuffix = _configuration["AZURE_ENV_SUFFIX"] ?? "D";

        switch (construct)
        {
            case Azure.Provisioning.Redis.RedisResource redisCache:
                redisCache.Name = $"{UniqueNamePrefix}-{redisCache.BicepIdentifier.ToLowerInvariant()}-{environmentSuffix}";
                break;
            // Future: Add other Azure services as needed
        }
    }
}
```

#### Part 2: Dynamic Bicep Parameters (Core Infrastructure)

Uses parameter-driven Bicep templates that adapt to environment-specific configurations:

```bicep
// main.bicep
@description('Environment suffix for resource naming')
param environmentSuffix string

// resources.bicep
param environmentSuffix string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'sv-mi-${environmentSuffix}'
  location: location
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'svacr${toLower(environmentSuffix)}'
  location: location
}
```

#### Part 3: Environment Integration

**Local Development:**

```powershell
# Deploy-WithCustomNames.ps1 (Legacy support)
$env:AZURE_ENV_SUFFIX = $EnvironmentSuffix
azd env set AZURE_ENV_SUFFIX $EnvironmentSuffix
azd up
```

**CI/CD Pipeline - Staged Deployment:**

```yaml
# GitHub Actions staged workflow
jobs:
  build-and-test: # ✅ First - validate code

  deploy-dev: # ✅ Second - automatic Dev deployment
    needs: build-and-test

  deploy-test: # ⚠️ Third - manual approval + Dev success required
    needs: deploy-dev
    environment: Test # Requires manual approval
```

### 🌍 Environment Support

| Environment | Suffix | Redis Cache  | Container Registry | Log Analytics | Container Apps Env | Managed Identity |
| ----------- | ------ | ------------ | ------------------ | ------------- | ------------------ | ---------------- |
| Development | `D`    | `sv-cache-D` | `svacrD`           | `sv-law-D`    | `sv-cae-D`         | `sv-mi-D`        |
| Test        | `T`    | `sv-cache-T` | `svacrT`           | `sv-law-T`    | `sv-cae-T`         | `sv-mi-T`        |
| Staging     | `S`    | `sv-cache-S` | `svacrS`           | `sv-law-S`    | `sv-cae-S`         | `sv-mi-S`        |
| Production  | `P`    | `sv-cache-P` | `svacrP`           | `sv-law-P`    | `sv-cae-P`         | `sv-mi-P`        |

### 🔄 Automated Workflow

The solution now supports **both local development and CI/CD pipelines** with dynamic parameter configuration:

#### Local Development Workflow

```powershell
# Single command deployment for any environment
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "P"
azd up
```

#### CI/CD Pipeline Workflow

```yaml
# GitHub Actions matrix strategy
strategy:
  matrix:
    include:
      - environment: Dev
        environment-suffix: D
      - environment: Test
        environment-suffix: T

steps:
  - uses: azure/login@v1
  - run: azd env set AZURE_ENV_SUFFIX ${{ matrix.environment-suffix }}
  - run: azd up --confirm
```

**What happens automatically:**

1. **Environment Setup**: Sets `AZURE_ENV_SUFFIX` environment variable
2. **Dynamic Parameters**: Bicep templates use `${AZURE_ENV_SUFFIX}` from parameters file
3. **Custom Naming Application**: All resources follow the `sv-*-{env}` naming convention
4. **Multi-Environment Support**: Same templates work across Dev, Test, Staging, Production
5. **CI/CD Integration**: GitHub Actions workflows handle environment-specific deployments

### 🌍 Multi-Environment Support

| Environment | Suffix | Example Resource Group | Redis Cache  | Container Registry | Log Analytics | Container Apps Env | Managed Identity |
| ----------- | ------ | ---------------------- | ------------ | ------------------ | ------------- | ------------------ | ---------------- |
| Development | `D`    | `rg-Dev-eastus`        | `sv-cache-D` | `svacrd`           | `sv-law-D`    | `sv-cae-D`         | `sv-mi-D`        |
| Test        | `T`    | `rg-Test-eastus`       | `sv-cache-T` | `svacrt`           | `sv-law-T`    | `sv-cae-T`         | `sv-mi-T`        |
| Staging     | `S`    | `rg-Staging-eastus`    | `sv-cache-S` | `svacrs`           | `sv-law-S`    | `sv-cae-S`         | `sv-mi-S`        |
| Production  | `P`    | `rg-Production-eastus` | `sv-cache-P` | `svacrp`           | `sv-law-P`    | `sv-cae-P`         | `sv-mi-P`        |

### 📋 Complete Resource Naming Reference

| Resource Type                  | Example Name           | Naming Method                      | Configuration Location               |
| ------------------------------ | ---------------------- | ---------------------------------- | ------------------------------------ |
| **Azure Redis Cache**          | `sv-cache-P`           | ✅ FixedNameInfrastructureResolver | `FixedNameInfrastructureResolver.cs` |
| **Container Registry**         | `svacrp`               | 🎯 Dynamic Bicep Parameter         | `infra/resources.bicep`              |
| **Log Analytics Workspace**    | `sv-law-P`             | 🎯 Dynamic Bicep Parameter         | `infra/resources.bicep`              |
| **Container Apps Environment** | `sv-cae-P`             | 🎯 Dynamic Bicep Parameter         | `infra/resources.bicep`              |
| **Managed Identity**           | `sv-mi-P`              | 🎯 Dynamic Bicep Parameter         | `infra/resources.bicep`              |
| **API Service**                | `sv-api-service-dev`   | 📝 Manual (Program.cs)             | Service definitions                  |
| **Web Frontend**               | `sv-web-frontend-dev`  | 📝 Manual (Program.cs)             | Service definitions                  |
| **Resource Group**             | `rg-Production-eastus` | 🎯 Dynamic Bicep Parameter         | `infra/main.bicep`                   |

### 🔧 Technical Implementation Details

#### Key Files Structure

```text
infra/
├── main.bicep                              # ✅ Orchestrates with environmentSuffix parameter
├── main.parameters.json                    # ✅ Maps environmentSuffix to ${AZURE_ENV_SUFFIX}
├── resources.bicep                         # ✅ Dynamic naming using environmentSuffix
├── cache/
│   ├── cache.module.bicep                  # ✅ Dynamic Redis cache naming
│   └── cache-roles/
│       └── cache-roles.module.bicep        # ✅ Dynamic role assignments
.github/workflows/
├── demo89x-main.yaml                      # ✅ Matrix strategy with environment mapping
└── demo89x-deploy.yaml                    # ✅ Reusable workflow with environment-suffix
src/HelloAspireApp.AppHost/
├── FixedNameInfrastructureResolver.cs      # ✅ Aspire resource naming
├── Deploy-WithCustomNames.ps1             # 🔄 Legacy script (still functional)
└── Program.cs                              # ✅ Resolver registration
```

#### Environment Variable Flow

```mermaid
graph LR
    A[GitHub Environment Variables] --> B[workflow: environment-suffix]
    B --> C[azd env set AZURE_ENV_SUFFIX]
    C --> D[main.parameters.json: ${AZURE_ENV_SUFFIX}]
    D --> E[Bicep Templates: environmentSuffix]
    E --> F[Azure Resources: sv-*-{env}]

    G[Local: Deploy-WithCustomNames.ps1] --> C
    H[FixedNameInfrastructureResolver] --> I[AZURE_ENV_SUFFIX config]
    I --> F
```

#### FixedNameInfrastructureResolver Registration

```csharp
// In Program.cs (AppHost)
builder.Services.Configure<AzureProvisioningOptions>(options =>
{
    options.ProvisioningBuildOptions.InfrastructureResolvers.Insert(0,
        new FixedNameInfrastructureResolver(builder.Configuration));
});
```

#### Dynamic Parameter Configuration

```json
// infra/main.parameters.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentSuffix": {
      "value": "${AZURE_ENV_SUFFIX}"
    }
  }
}
```

#### Bicep Template Example

```bicep
// infra/resources.bicep
@description('Environment suffix for resource naming')
param environmentSuffix string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'sv-mi-${environmentSuffix}'
  location: location
  tags: union(tags, { 'azd-service-name': 'managedidentity' })
}
```

---

## 🚀 Getting Started

### Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions

### 1. Clone and Setup

```bash
git clone <repository-url>
cd aspire-demo89x
```

### 2. Local Development Setup

```powershell
# Navigate to AppHost
cd src\HelloAspireApp.AppHost

# Deploy to Development (default)
.\Deploy-WithCustomNames.ps1

# Or specify environment
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "T"  # Test environment

# Deploy to Azure
azd up
```

### 3. GitHub Actions Setup

1. **Create GitHub Environments:** Follow the [GitHub Environments Setup Guide](docs/github-environments-setup.md)
2. **Configure Secrets:** Set up Azure service principal credentials
3. **Trigger Workflow:** Push to main branch or manually trigger via GitHub Actions

### 4. Verification

```powershell
# Test the complete workflow
.\Test-DynamicNaming.ps1 -EnvironmentSuffix "D"

# Skip deployment, test compilation only
.\Test-DynamicNaming.ps1 -EnvironmentSuffix "D" -SkipDeploy

# Cleanup test resources
.\Test-DynamicNaming.ps1 -EnvironmentSuffix "D" -CleanupOnly
```

---

## 📚 Documentation

- [GitHub Environments Setup Guide](docs/github-environments-setup.md) - Configure GitHub Environments for CI/CD
- [GitHub Actions Workflows](docs/github-actions-workflows.md) - Understanding the CI/CD pipeline
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions

---

## 🔧 Troubleshooting

### Common Issues

**Bicep compilation errors after `azd infra generate`**

- Run `.\Test-DynamicNaming.ps1 -EnvironmentSuffix "D" -SkipDeploy` to validate templates

**Resources created with wrong names**

- Verify `AZURE_ENV_SUFFIX` is set: `azd env get-values`
- Check GitHub Environment variables match expected values

**GitHub Actions workflow failures**

- Ensure GitHub Environments are properly configured
- Verify environment suffix mapping in matrix strategy

### Debug Commands

```powershell
# Check environment variables
azd env get-values

# Validate Bicep templates
az bicep build --file infra/main.bicep

# Test complete workflow
.\Test-DynamicNaming.ps1 -EnvironmentSuffix "D"
```

### Legacy Support

The `Deploy-WithCustomNames.ps1` script is maintained for backwards compatibility but **the dynamic parameter approach is recommended** for new implementations.

---

## Federation Credentials

```text
repo:Swamy-s-Tech-Skills-Academy/aspire-demo89x:ref:refs/heads/main
repo:Swamy-s-Tech-Skills-Academy/aspire-demo89x:environment:Dev
repo:Swamy-s-Tech-Skills-Academy/aspire-demo89x:environment:Test
```

cd src\HelloAspireApp.AppHost
.\Deploy-WithCustomNames.ps1

````

**Issue**: Script reports "No changes needed" but names are wrong

```powershell
# Solution: Re-generate infrastructure first
azd infra generate --force
.\Deploy-WithCustomNames.ps1
````

**Issue**: FixedNameInfrastructureResolver not working

```powershell
# Solution: Verify environment variable is set
$env:AZURE_ENV_SUFFIX = "P"
# Check Program.cs has resolver registration
```

### 📁 Generated File Structure

After running the script, your infrastructure will look like:

```text
infra/
├── main.bicep                              # Main orchestration
├── main.parameters.json                    # Parameters (includes environmentSuffix)
├── resources.bicep                         # ✅ Fixed: Custom named core resources
├── cache/
│   └── cache.module.bicep                  # ✅ Auto: sv-cache-P (via resolver)
└── sv-api-service-dev.tmpl.yaml           # Container app definitions
```

### ⚡ Script Output Example

```powershell
🚀 Deploying with Custom Resource Names
   Environment Suffix: P
   Unique Prefix: sv

📝 Set AZURE_ENV_SUFFIX=P

🔨 Generating infrastructure with azd...
✅ Infrastructure generated successfully

🔧 Applying custom resource names...
   ✅ Fixed: name: 'mi-${resourceToken}'
   ✅ Fixed: name: replace('acr-${resourceToken}', '-', '')
   ✅ Fixed: name: 'law-${resourceToken}'
   ✅ Fixed: name: 'cae-${resourceToken}'

🎉 Resource names fixed successfully!

📋 Final Resource Names:
   Managed Identity: sv-mi-P
   Container Registry: svacrp
   Log Analytics: sv-law-P
   Container Apps Env: sv-cae-P
   Redis Cache: sv-cache-P (via FixedNameInfrastructureResolver)

🎯 Ready for deployment! Run:
   azd up

✨ All resource names are now consistent with your naming convention!
```

---

## 📚 Legacy Information

### Manual Commands (Not Recommended - Use Script Instead)

```powershell
# Old manual workflow (replaced by Deploy-WithCustomNames.ps1)
$env:AZURE_ENV_SUFFIX = "P"
azd infra generate --force
# Manual Bicep file editing required...
azd up
```

## Federation Credentials

```text
repo:Swamy-s-Tech-Skills-Academy/aspire-demo89x:ref:refs/heads/main

repo:Swamy-s-Tech-Skills-Academy/aspire-demo89x:environment:Dev
```
