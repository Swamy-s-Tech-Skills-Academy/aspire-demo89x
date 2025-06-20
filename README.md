# .NET Aspire With AI Stack

A distributed AI-powered architecture built with .NET Aspire, PostgreSQL, Redis, RabbitMQ, Keycloak, Ollama, and VectorDB.

## Deployment

```powershell
D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> az account show

D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> azd init

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

## Custom Resource Naming

This project implements a `FixedNameInfrastructureResolver` that provides consistent, predictable naming for all Azure resources instead of auto-generated unique names.

### Configuration

The resolver requires the following configuration:

```json
{
  "Azure": {
    "ResourceGroup": "your-resource-group-name-dev" // Must end with "dev" for dev environment
  }
}
```

### Naming Patterns

| Resource Type                  | Pattern              | Example              |
| ------------------------------ | -------------------- | -------------------- |
| **Container Apps**             | `sv-{service}-{env}` | `sv-api-service-dev` |
| **Redis Cache**                | `sv-{service}-{env}` | `sv-cache-dev`       |
| **Storage Account**            | `sv{service}{env}`   | `svcachedev`         |
| **Container Registry**         | `svacr{env}`         | `svacrdev`           |
| **Log Analytics Workspace**    | `sv-law{env}`        | `sv-law-dev`         |
| **Container Apps Environment** | `sv-cae{env}`        | `sv-cae-dev`         |

### Features

- **Environment Detection**: Automatically detects dev environment from resource group name
- **Naming Compliance**: Respects Azure naming restrictions (some resources don't allow hyphens)
- **Consistent Branding**: All resources use the "sv" company prefix
- **Predictable Names**: Easy to identify and manage resources in Azure Portal

### Service Configuration

The AppHost defines the following services with custom names:

```csharp
var cache = builder.AddRedis("cache");
var apiService = builder.AddProject<Projects.HelloAspireApp_ApiService>("api-service");
builder.AddProject<Projects.HelloAspireApp_Web>("web-frontend")
```

These service names become the `{service}` part in the naming patterns above.

```text
SUCCESS: Your app is ready for the cloud!
Run azd up to provision and deploy your app to Azure.
Run azd add to add new Azure components to your project.
Run azd infra gen to generate IaC for your project to disk, allowing you to manually manage it.
See ./next-steps.md for more information on configuring your app.
```
