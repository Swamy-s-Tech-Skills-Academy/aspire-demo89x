# .NET Aspire With Custom Azure Resource Naming

A .NET Aspire project implementing enterprise-grade Azure resource naming conventions with automated infrastructure generation and custom naming enforcement.

## 🚀 Quick Start - Automated Deployment

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

This script automatically:

1. Sets the `AZURE_ENV_SUFFIX` environment variable
2. Generates infrastructure using `azd infra generate --force`
3. Applies custom naming conventions to all resources
4. Provides a summary of the naming changes

All resources will follow the `sv-*-{env}` naming convention for easy identification and management in the Azure Portal.

---

## 🏗️ Custom Azure Resource Naming Solution

This project implements a comprehensive, **fully automated** custom naming convention for Azure resources that addresses the challenges of maintaining consistent naming across environments when using .NET Aspire and Azure Developer CLI (azd).

### 🎯 Problem Statement

When using `azd infra generate` (or `azd infra synth`) with .NET Aspire:

- Azure resources get auto-generated names with random suffixes (e.g., `acr-abc123xyz`)
- Manual edits to Bicep files are overwritten each time infrastructure is regenerated
- Maintaining consistent naming conventions across environments becomes challenging
- Enterprise naming standards are difficult to enforce automatically

### ✅ Solution: Two-Part Automated Approach

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

#### Part 2: PowerShell Post-Processing Script (Core Infrastructure)

Handles core infrastructure resources that azd generates automatically:

```powershell
# Deploy-WithCustomNames.ps1
# Automatically applies custom naming after azd infra generate

param(
    [string]$EnvironmentSuffix = $env:AZURE_ENV_SUFFIX ?? "D",
    [string]$UniquePrefix = "sv"
)

# 1. Set environment variable for resolver
$env:AZURE_ENV_SUFFIX = $EnvironmentSuffix

# 2. Generate infrastructure
azd infra generate --force

# 3. Apply custom naming patterns to Bicep files
# ... (replaces default names with custom naming convention)
```

### 🌍 Environment Support

| Environment | Suffix | Redis Cache  | Container Registry | Log Analytics | Container Apps Env | Managed Identity |
| ----------- | ------ | ------------ | ------------------ | ------------- | ------------------ | ---------------- |
| Development | `D`    | `sv-cache-D` | `svacrD`           | `sv-law-D`    | `sv-cae-D`         | `sv-mi-D`        |
| Test        | `T`    | `sv-cache-T` | `svacrT`           | `sv-law-T`    | `sv-cae-T`         | `sv-mi-T`        |
| Staging     | `S`    | `sv-cache-S` | `svacrS`           | `sv-law-S`    | `sv-cae-S`         | `sv-mi-S`        |
| Production  | `P`    | `sv-cache-P` | `svacrP`           | `sv-law-P`    | `sv-cae-P`         | `sv-mi-P`        |

### 🔄 Automated Workflow

The complete workflow is now **fully automated** with a single script:

```powershell
# Deploy to any environment with one command
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "P"
azd up
```

**What happens automatically:**

1. **Environment Setup**: Sets `AZURE_ENV_SUFFIX` environment variable
2. **Infrastructure Generation**: Runs `azd infra generate --force`
3. **Custom Naming Application**: Patches generated Bicep files with enterprise naming
4. **Validation**: Provides summary of all resource names
5. **Ready for Deployment**: Infrastructure is ready for `azd up`

### 📋 Complete Resource Naming Reference

| Resource Type                  | Example Name          | Naming Method                      | Location                |
| ------------------------------ | --------------------- | ---------------------------------- | ----------------------- |
| **Azure Redis Cache**          | `sv-cache-P`          | ✅ FixedNameInfrastructureResolver | Auto-generated Bicep    |
| **Container Registry**         | `svacrp`              | 🔧 PowerShell Script               | `infra/resources.bicep` |
| **Log Analytics Workspace**    | `sv-law-P`            | 🔧 PowerShell Script               | `infra/resources.bicep` |
| **Container Apps Environment** | `sv-cae-P`            | 🔧 PowerShell Script               | `infra/resources.bicep` |
| **Managed Identity**           | `sv-mi-P`             | 🔧 PowerShell Script               | `infra/resources.bicep` |
| **API Service**                | `sv-api-service-dev`  | Manual (Program.cs)                | Service definitions     |
| **Web Frontend**               | `sv-web-frontend-dev` | Manual (Program.cs)                | Service definitions     |

### 🔧 Technical Implementation Details

#### FixedNameInfrastructureResolver Registration

```csharp
// In Program.cs (AppHost)
builder.Services.Configure<AzureProvisioningOptions>(options =>
{
    options.ProvisioningBuildOptions.InfrastructureResolvers.Insert(0,
        new FixedNameInfrastructureResolver(builder.Configuration));
});
```

#### PowerShell Script Key Replacements

The script automatically replaces these patterns in `infra/resources.bicep`:

```bicep
// Before (azd generated):
name: 'mi-${resourceToken}'

// After (script applied):
name: 'sv-mi-P'

// Before:
name: replace('acr-${resourceToken}', '-', '')

// After:
name: 'sv' + 'acr' + toLower('P')
```

### 🚀 Getting Started

#### Prerequisites

```powershell
# Enable alpha features for azd
azd config set alpha.infraSynth on
azd config set alpha.resourceGroupDeployments on

azd infra generate --force

# Authenticate with Azure
azd auth login --scope https://management.azure.com//.default
```

#### First-Time Setup

```powershell
# Navigate to AppHost directory
cd src\HelloAspireApp.AppHost

# Initialize azd project (if not done already)
azd init

# Deploy to Development (default)
.\Deploy-WithCustomNames.ps1
azd up
```

#### Multi-Environment Deployment

```powershell
# Deploy to Production
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "P"
azd up

# Deploy to Test
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "T"
azd up
```

### 🎯 Benefits of This Approach

✅ **Fully Automated**: No manual Bicep file editing required  
✅ **Environment Agnostic**: Single script works for all environments  
✅ **Regeneration Safe**: Can re-run `azd infra generate` anytime  
✅ **Enterprise Ready**: Consistent naming across all resources  
✅ **Maintainable**: Changes in one place affect entire naming convention  
✅ **Future Proof**: Easy to add new resource types to the naming system

### 🔍 Troubleshooting

#### Common Issues

**Issue**: Resources still have default names after running script

```powershell
# Solution: Ensure you're in the correct directory
cd src\HelloAspireApp.AppHost
.\Deploy-WithCustomNames.ps1
```

**Issue**: Script reports "No changes needed" but names are wrong

```powershell
# Solution: Re-generate infrastructure first
azd infra generate --force
.\Deploy-WithCustomNames.ps1
```

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
