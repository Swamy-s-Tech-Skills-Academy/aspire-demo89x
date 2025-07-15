# Configuration Reference

This document provides a comprehensive reference for all configuration options available in the aspire-demo89x project.

## 🔧 Environment Variables

### Required Environment Variables

These variables must be set for the application to function properly.

#### Azure Configuration

| Variable                | Description                              | Example             | Required |
| ----------------------- | ---------------------------------------- | ------------------- | -------- |
| `AZURE_ENV_NAME`        | Environment name for Azure Developer CLI | `aspire-dev-001`    | Yes      |
| `AZURE_LOCATION`        | Azure region for deployment              | `eastus`            | Yes      |
| `AZURE_ENV_SUFFIX`      | Environment suffix for resource naming   | `D`                 | Yes      |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID                    | `12345678-1234-...` | Yes      |
| `AZURE_TENANT_ID`       | Azure tenant ID                          | `87654321-4321-...` | Yes      |
| `AZURE_CLIENT_ID`       | Service Principal client ID              | `abcdef12-3456-...` | Yes      |

#### Optional Azure Configuration

| Variable                         | Description                | Example                 | Default                     |
| -------------------------------- | -------------------------- | ----------------------- | --------------------------- |
| `AZURE_RESOURCE_GROUP`           | Custom resource group name | `rg-Custom-eastus`      | `rg-{Environment}-{Region}` |
| `AZURE_CREDENTIALS`              | Service Principal JSON     | `{"clientId":"..."}`    | Uses federated credentials  |
| `AZD_INITIAL_ENVIRONMENT_CONFIG` | Initial azd configuration  | `{"location":"eastus"}` | Empty                       |

### GitHub Environment Variables

#### Dev Environment

```yaml
AZURE_ENV_NAME: aspire-dev-001
AZURE_LOCATION: eastus
AZURE_ENV_SUFFIX: D
```

#### Test Environment

```yaml
AZURE_ENV_NAME: aspire-test-001
AZURE_LOCATION: eastus
AZURE_ENV_SUFFIX: T
```

#### Production Environment (Example)

```yaml
AZURE_ENV_NAME: aspire-prod-001
AZURE_LOCATION: eastus
AZURE_ENV_SUFFIX: P
```

## 📁 Configuration Files

### Application Settings

#### appsettings.json (Web Frontend)

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "cache": "your-redis-connection-string"
  },
  "WeatherApi": {
    "BaseUrl": "https://api-service",
    "Timeout": "00:00:30"
  }
}
```

#### appsettings.json (API Service)

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "cache": "your-redis-connection-string"
  },
  "WeatherSettings": {
    "CacheDurationMinutes": 5,
    "DefaultCity": "Seattle"
  }
}
```

#### appsettings.Development.json

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Information"
    }
  },
  "DetailedErrors": true,
  "ConnectionStrings": {
    "cache": "localhost:6379"
  }
}
```

### Azure Developer CLI Configuration

#### azure.yaml

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/Azure/azure-dev/main/schemas/v1.0/azure.yaml.json

name: helloaspireapp-apphost
metadata:
  template: aspire-demo89x@1.0.0

services:
  app:
    language: dotnet
    project: ./HelloAspireApp.AppHost.csproj
    host: containerapp

infra:
  provider: bicep
  path: ./infra
  parameters:
    environmentName: ${AZURE_ENV_NAME}
    location: ${AZURE_LOCATION}
    environmentSuffix: ${AZURE_ENV_SUFFIX}
```

### Infrastructure Configuration

#### main.parameters.json

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

## 🔨 Build Configuration

### Project Files

#### HelloAspireApp.AppHost.csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <UserSecretsId>aspire-demo89x-apphost</UserSecretsId>
    <IsAspireHost>true</IsAspireHost>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Aspire.Hosting.AppHost" Version="9.0.0" />
    <PackageReference Include="Aspire.Hosting.Azure.Redis" Version="9.0.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\HelloAspireApp.ApiService\HelloAspireApp.ApiService.csproj" />
    <ProjectReference Include="..\HelloAspireApp.ServiceDefaults\HelloAspireApp.ServiceDefaults.csproj" />
    <ProjectReference Include="..\HelloAspireApp.Web\HelloAspireApp.Web.csproj" />
  </ItemGroup>

</Project>
```

#### HelloAspireApp.ApiService.csproj

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <InvariantGlobalization>true</InvariantGlobalization>
    <UserSecretsId>aspire-demo89x-api</UserSecretsId>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="8.0.0" />
    <PackageReference Include="Microsoft.Extensions.Caching.StackExchangeRedis" Version="8.0.0" />
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.4.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\HelloAspireApp.ServiceDefaults\HelloAspireApp.ServiceDefaults.csproj" />
  </ItemGroup>

</Project>
```

### Solution Configuration

#### aspire-demo89x.sln

```
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "HelloAspireApp.AppHost", "src\HelloAspireApp.AppHost\HelloAspireApp.AppHost.csproj", "{...}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "HelloAspireApp.ApiService", "src\HelloAspireApp.ApiService\HelloAspireApp.ApiService.csproj", "{...}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "HelloAspireApp.ServiceDefaults", "src\HelloAspireApp.ServiceDefaults\HelloAspireApp.ServiceDefaults.csproj", "{...}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "HelloAspireApp.Web", "src\HelloAspireApp.Web\HelloAspireApp.Web.csproj", "{...}"
EndProject
```

## 🐳 Container Configuration

### Dockerfile (Generated by .NET Aspire)

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["HelloAspireApp.ApiService/HelloAspireApp.ApiService.csproj", "HelloAspireApp.ApiService/"]
COPY ["HelloAspireApp.ServiceDefaults/HelloAspireApp.ServiceDefaults.csproj", "HelloAspireApp.ServiceDefaults/"]
RUN dotnet restore "HelloAspireApp.ApiService/HelloAspireApp.ApiService.csproj"
COPY . .
WORKDIR "/src/HelloAspireApp.ApiService"
RUN dotnet build "HelloAspireApp.ApiService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "HelloAspireApp.ApiService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "HelloAspireApp.ApiService.dll"]
```

## 🎯 Bicep Configuration

### Region Abbreviations

The following region abbreviations are configured in `main.bicep`:

```bicep
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
```

### Resource Naming Templates

```bicep
// Managed Identity
name: 'sv-mi-${environmentSuffix}-${regionAbbreviation}'

// Container Registry
name: 'svacr${toLower(environmentSuffix)}${regionAbbreviation}'

// Log Analytics Workspace
name: 'sv-law-${environmentSuffix}-${regionAbbreviation}'

// Container Apps Environment
name: 'sv-cae-${environmentSuffix}-${regionAbbreviation}'

// Redis Cache
name: 'sv-cache-${environmentSuffix}-${regionAbbreviation}'
```

## 🔐 Security Configuration

### Managed Identity Configuration

```bicep
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'sv-mi-${environmentSuffix}-${regionAbbreviation}'
  location: location
  tags: tags
}
```

### Role Assignments

```bicep
// ACR Pull role for Container Apps
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

### Redis Cache Security

```bicep
resource cache 'Microsoft.Cache/redis@2023-08-01' = {
  name: 'sv-cache-${environmentSuffix}-${regionAbbreviation}'
  location: location
  properties: {
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
  tags: tags
}
```

## 📊 Monitoring Configuration

### Application Insights

```csharp
// Configure Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Custom telemetry
builder.Services.AddSingleton<TelemetryClient>();
```

### Health Checks

```csharp
// Register health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy())
    .AddRedis(builder.Configuration.GetConnectionString("cache"));

// Health check endpoint
app.MapHealthChecks("/health");
```

### Logging Configuration

```csharp
// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddApplicationInsights();

// Structured logging
builder.Services.Configure<LoggerFilterOptions>(options =>
{
    options.MinLevel = LogLevel.Information;
});
```

## 🔄 Cache Configuration

### Redis Configuration

```csharp
// Register Redis cache
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("cache");
    options.InstanceName = "AspireDemo";
});

// Cache settings
public class CacheSettings
{
    public int DefaultExpirationMinutes { get; set; } = 5;
    public string KeyPrefix { get; set; } = "aspire-demo";
}
```

## 🚀 Deployment Configuration

### GitHub Actions Secrets

Required repository secrets:

```yaml
AZURE_CLIENT_ID: "12345678-1234-1234-1234-123456789012"
AZURE_TENANT_ID: "87654321-4321-4321-4321-210987654321"
AZURE_SUBSCRIPTION_ID: "abcdef12-3456-7890-abcd-ef1234567890"
```

### Environment Protection Rules

```yaml
# Test Environment
required_reviewers:
  - "@username"
  - "@team/reviewers"
wait_timer: 0
prevent_self_review: true
```

## 📚 Reference Links

### Microsoft Documentation

- [.NET Aspire Configuration](https://learn.microsoft.com/en-us/dotnet/aspire/configuration)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Bicep Templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

### Configuration Examples

- [ASP.NET Core Configuration](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)
- [Azure Container Apps Configuration](https://learn.microsoft.com/en-us/azure/container-apps/configuration)
- [Redis Cache Configuration](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-web-app-aspnet-core-howto)

---

_This configuration reference is comprehensive and covers all aspects of the aspire-demo89x project configuration. Keep it updated as the project evolves._
