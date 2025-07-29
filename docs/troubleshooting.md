# Troubleshooting Guide

This guide provides solutions to common issues you might encounter while developing, deploying, or running the aspire-demo89x application.

## 🔍 Quick Diagnostics

### Health Check Commands

```bash
# Check overall system health
azd show --output json

# Verify Azure CLI authentication
az account show

# Check Docker status
docker info

# Verify .NET installation
dotnet --info

# Check Aspire workload
dotnet workload list
```

## 🚨 Common Issues

### 1. Authentication Problems

#### Issue: Azure CLI authentication expired

**Symptoms:**

- "Authentication failed" errors
- 401 Unauthorized responses
- `azd` commands failing

**Solution:**

```bash
# Re-authenticate with Azure CLI
az login

# Re-authenticate with Azure Developer CLI
azd auth login

# Verify authentication
az account show
azd auth login --check-status
```

#### Issue: Service Principal authentication issues

**Symptoms:**

- GitHub Actions deployment failures
- "Invalid client secret" errors

**Solution:**

1. Verify service principal exists:

   ```bash
   az ad sp show --id <your-client-id>
   ```

2. Check service principal permissions:

   ```bash
   az role assignment list --assignee <your-client-id>
   ```

3. Regenerate client secret if needed:
   ```bash
   az ad sp credential reset --id <your-client-id>
   ```

### 2. Resource Naming Conflicts

#### Issue: Resource names already exist

**Symptoms:**

- "Resource name already exists" errors
- Deployment failures in `azd provision`

**Solution:**

```bash
# Use different environment suffix
azd env set AZURE_ENV_SUFFIX X

# Or use different region
azd env set AZURE_LOCATION westus2

# Check existing resources
az resource list --query "[?contains(name, 'sv-')]" --output table
```

#### Issue: Invalid resource names

**Symptoms:**

- "Invalid resource name" errors
- Bicep template validation failures

**Solution:**

1. Check Azure naming conventions
2. Verify region abbreviation mapping in `main.bicep`
3. Ensure environment suffix is single character

### 3. Container Registry Issues

#### Issue: Docker push failures

**Symptoms:**

- "Authentication required" when pushing images
- "Repository not found" errors

**Solution:**

```bash
# Login to Azure Container Registry
az acr login --name <your-registry-name>

# Get registry credentials
az acr credential show --name <your-registry-name>

# Test registry connectivity
docker pull <your-registry-name>.azurecr.io/hello-world
```

#### Issue: Container image pull failures

**Symptoms:**

- Container Apps deployment fails
- "Image not found" errors

**Solution:**

1. Verify image exists in registry:

   ```bash
   az acr repository list --name <your-registry-name>
   ```

2. Check managed identity has ACR pull permissions:

   ```bash
   az role assignment list --assignee <managed-identity-id> --scope <acr-resource-id>
   ```

### 4. Network Connectivity Issues

#### Issue: Service-to-service communication failures

**Symptoms:**

- HTTP timeout errors
- "Connection refused" errors
- Services can't reach each other

**Solution:**

```bash
# Check Container Apps ingress configuration
az containerapp show --name <app-name> --resource-group <rg-name> --query properties.configuration.ingress

# Verify service endpoints
az containerapp show --name <app-name> --resource-group <rg-name> --query properties.configuration.ingress.fqdn

# Test connectivity
curl -I https://<your-app-fqdn>
```

#### Issue: Redis connection failures

**Symptoms:**

- "Connection timeout" errors
- Cache-related exceptions

**Solution:**

```bash
# Check Redis configuration
az redis show --name <redis-name> --resource-group <rg-name>

# Test Redis connectivity
redis-cli -h <redis-host> -p 6380 -a <redis-password> ping

# Verify firewall rules
az redis firewall-rule list --name <redis-name> --resource-group <rg-name>
```

### 5. GitHub Actions Issues

#### Issue: Workflow permissions errors

**Symptoms:**

- "Permission denied" in GitHub Actions
- "Insufficient permissions" errors

**Solution:**

1. Check repository permissions:

   - Settings → Actions → General → Workflow permissions
   - Ensure "Read and write permissions" is selected

2. Verify GitHub Environment protection rules
3. Check if environments exist and are properly configured

#### Issue: Environment variable not found

**Symptoms:**

- "Environment variable not set" errors
- Null reference exceptions in deployment

**Solution:**

1. Verify environment variables are set:

   ```bash
   # In GitHub repository settings
   Settings → Environments → [Environment Name] → Environment variables
   ```

2. Check variable names match exactly:

   ```yaml
   # In workflow file
   AZURE_ENV_NAME: ${{ vars.AZURE_ENV_NAME }}
   ```

### 6. Multi-Region Deployment Issues

#### Issue: Deployment fails in one region but succeeds in another

**Symptoms:**

- Matrix job succeeds in East US but fails in Central US
- Resource naming conflicts between regions
- Different resource availability in regions

**Solution:**

1. Check region-specific resource availability:

   ```bash
   # Verify all resources are available in both regions
   az provider show --namespace Microsoft.App --query "resourceTypes[?resourceType=='containerApps'].locations" --output table
   ```

2. Ensure region abbreviations are correct:

   ```yaml
   # In main.bicep
   var regionAbbreviations = {
     eastus: 'use'
     centralus: 'usc'
   }
   ```

3. Monitor matrix job logs separately:

   ```bash
   # In GitHub Actions, check individual matrix job logs
   # Dev - East US: sv-aspire-demo89x-api-D-use
   # Dev - Central US: sv-aspire-demo89x-api-D-usc
   ```

#### Issue: Resource naming conflicts across regions

**Symptoms:**

- "Resource name already exists" errors
- Resources from different regions conflicting

**Solution:**

1. Verify resource naming includes region abbreviation:

   ```bash
   # Expected naming pattern
   sv-aspire-demo89x-api-D-use    # East US
   sv-aspire-demo89x-api-D-usc    # Central US
   ```

2. Check Bicep template includes region suffix:

   ```bicep
   var regionAbbr = regionAbbreviations[location]
   var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location))
   name: '${serviceName}-${environmentName}-${regionAbbr}'
   ```

#### Issue: Cross-region connectivity problems

**Symptoms:**

- Services in different regions can't communicate
- Load balancer not distributing traffic properly

**Solution:**

1. Each region deployment is independent - verify services within same region:

   ```bash
   # Test East US services
   curl https://sv-aspire-demo89x-web-D-use.azurecontainerapps.io/health

   # Test Central US services
   curl https://sv-aspire-demo89x-web-D-usc.azurecontainerapps.io/health
   ```

2. Check container app environment configuration per region:

   ```bash
   # East US environment
   az containerapp env show --name sv-aspire-demo89x-env-D-use --resource-group sv-aspire-demo89x-rg-D-use

   # Central US environment
   az containerapp env show --name sv-aspire-demo89x-env-D-usc --resource-group sv-aspire-demo89x-rg-D-usc
   ```

### 7. Log Analytics Workspace Issues

#### Issue: Using existing Log Analytics workspace

**Symptoms:**

- Want to reuse existing centralized logging workspace
- Avoid creating multiple workspaces per environment

**Solution:**

1. Configure repository secrets for existing workspace:

   ```bash
   # Get workspace information
   az monitor log-analytics workspace show \
     --resource-group <existing-rg> \
     --workspace-name <existing-workspace> \
     --query "{customerId:customerId,id:id}"

   # Get workspace shared key
   az monitor log-analytics workspace get-shared-keys \
     --resource-group <existing-rg> \
     --workspace-name <existing-workspace> \
     --query "primarySharedKey"
   ```

2. Add to GitHub repository secrets:

   - `EXISTING_LOG_ANALYTICS_WORKSPACE_CUSTOMER_ID`: Customer ID from step 1
   - `EXISTING_LOG_ANALYTICS_WORKSPACE_ID`: Resource ID from step 1
   - `EXISTING_LOG_ANALYTICS_WORKSPACE_SHARED_KEY`: Shared key from step 1

3. Verify workspace connection in Container Apps:

   ```bash
   # Check if Container Apps environment uses existing workspace
   az containerapp env show \
     --name sv-aspire-demo89x-env-D-use \
     --resource-group sv-aspire-demo89x-rg-D-use \
     --query "properties.appLogsConfiguration"
   ```

#### Issue: Log Analytics workspace access denied

**Symptoms:**

- "Insufficient permissions" errors when connecting to existing workspace
- Logs not appearing in existing workspace

**Solution:**

1. Grant Service Principal access to existing workspace:

   ```bash
   # Add Log Analytics Contributor role
   az role assignment create \
     --assignee <service-principal-id> \
     --role "Log Analytics Contributor" \
     --scope <workspace-resource-id>
   ```

2. Verify workspace permissions:

   ```bash
   # Check role assignments on workspace
   az role assignment list \
     --scope <workspace-resource-id> \
     --assignee <service-principal-id>
   ```

### 8. Local Development Issues

#### Issue: Aspire Dashboard not accessible

**Symptoms:**

- Cannot access `https://localhost:15888`
- "Site can't be reached" errors

**Solution:**

```bash
# Check if port is in use
netstat -an | findstr :15888

# Try different port
dotnet run --dashboard-port 15889

# Check firewall settings
# Windows: Allow .NET through Windows Defender Firewall
```

#### Issue: Service discovery not working

**Symptoms:**

- Services can't find each other
- "Service not found" errors

**Solution:**

```csharp
// Verify service registration in AppHost
var apiService = builder.AddProject<Projects.HelloAspireApp_ApiService>("api-service");

// Check service name matches in client
public class WeatherApiClient
{
    public WeatherApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri("https://api-service/");
    }
}
```

### 9. Performance Issues

#### Issue: Slow application startup

**Symptoms:**

- Long startup times
- Timeout errors during deployment

**Solution:**

```csharp
// Optimize service registration
builder.Services.AddSingleton<IExpensiveService, ExpensiveService>();

// Use connection pooling
builder.Services.AddDbContextPool<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// Implement health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy());
```

#### Issue: High memory usage

**Symptoms:**

- Out of memory exceptions
- Container restarts

**Solution:**

```dockerfile
# Optimize Docker image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS base
WORKDIR /app

# Set resource limits
ENV DOTNET_GCHeapHardLimit=100000000
ENV DOTNET_GCHeapHardLimitPercent=75
```

## 🔧 Debugging Techniques

### 1. Logs Analysis

#### Application Logs

```bash
# View Container Apps logs
az containerapp logs show --name <app-name> --resource-group <rg-name>

# Stream logs in real-time
az containerapp logs tail --name <app-name> --resource-group <rg-name>

# Query Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == '<app-name>' | order by TimeGenerated desc | limit 100"
```

#### Infrastructure Logs

```bash
# Check deployment history
az deployment group list --resource-group <rg-name>

# View specific deployment
az deployment group show --resource-group <rg-name> --name <deployment-name>

# Check resource health
az resource show --resource-group <rg-name> --name <resource-name> --resource-type <resource-type>
```

### 2. Local Debugging

#### Debug with Visual Studio

1. Set multiple startup projects
2. Set breakpoints in services
3. Use F5 to start debugging
4. Monitor requests in Aspire Dashboard

#### Debug with VS Code

```json
// launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch AppHost",
      "type": "coreclr",
      "request": "launch",
      "program": "${workspaceFolder}/src/HelloAspireApp.AppHost/bin/Debug/net8.0/HelloAspireApp.AppHost.dll",
      "args": [],
      "cwd": "${workspaceFolder}/src/HelloAspireApp.AppHost",
      "stopAtEntry": false,
      "env": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  ]
}
```

### 3. Performance Profiling

#### Using dotnet-trace

```bash
# Install dotnet-trace
dotnet tool install --global dotnet-trace

# Collect trace
dotnet-trace collect --process-id <pid>

# Analyze trace file
# Open .nettrace file in Visual Studio or PerfView
```

#### Using Application Insights

```csharp
// Configure Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Custom telemetry
public class TelemetryService
{
    private readonly TelemetryClient _telemetryClient;

    public void TrackDependency(string dependencyName, string commandName,
        DateTimeOffset startTime, TimeSpan duration, bool success)
    {
        _telemetryClient.TrackDependency(dependencyName, commandName,
            startTime, duration, success);
    }
}
```

## 📊 Monitoring and Alerting

### Setting Up Alerts

```bash
# Create metric alert
az monitor metrics alert create \
  --name "High CPU Alert" \
  --resource-group <rg-name> \
  --scopes <resource-id> \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when CPU usage is high"

# Create log alert
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | where Level == 'Error' | summarize count() by bin(TimeGenerated, 5m)"
```

### Health Check Monitoring

```csharp
// Custom health check
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly ApplicationDbContext _context;

    public DatabaseHealthCheck(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await _context.Database.CanConnectAsync(cancellationToken);
            return HealthCheckResult.Healthy();
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy(ex.Message);
        }
    }
}
```

## 🆘 Emergency Procedures

### 1. Application Down

**Immediate Actions:**

```bash
# Check service status
azd show

# Restart Container Apps
az containerapp restart --name <app-name> --resource-group <rg-name>

# Check recent deployments
az deployment group list --resource-group <rg-name> --query "[?properties.provisioningState=='Failed']"
```

### 2. Database Issues

**Emergency Recovery:**

```bash
# Check database connectivity
az redis show --name <redis-name> --resource-group <rg-name>

# Restart Redis if needed
az redis restart --name <redis-name> --resource-group <rg-name>

# Check firewall rules
az redis firewall-rule list --name <redis-name> --resource-group <rg-name>
```

### 3. Rollback Procedures

**Quick Rollback:**

```bash
# Rollback to previous version
azd deploy --from-package <previous-package-path>

# Or redeploy stable version
git checkout <stable-commit>
azd deploy
```

## 📋 Troubleshooting Checklist

### Pre-Deployment

- [ ] All prerequisites installed
- [ ] Azure CLI authenticated
- [ ] Service Principal configured
- [ ] Environment variables set
- [ ] Bicep templates validated

### During Deployment

- [ ] Monitor deployment logs
- [ ] Check resource creation status
- [ ] Verify network connectivity
- [ ] Test service endpoints
- [ ] Validate health checks

### Post-Deployment

- [ ] Application responding correctly
- [ ] All services healthy
- [ ] Logs showing no errors
- [ ] Performance metrics normal
- [ ] Alerts configured

## 🔗 Additional Resources

### Microsoft Documentation

- [Azure Container Apps Troubleshooting](https://learn.microsoft.com/en-us/azure/container-apps/troubleshooting)
- [.NET Aspire Troubleshooting](https://learn.microsoft.com/en-us/dotnet/aspire/troubleshooting)
- [Azure Developer CLI Troubleshooting](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/troubleshoot)

### Community Resources

- [Stack Overflow - Azure Container Apps](https://stackoverflow.com/questions/tagged/azure-container-apps)
- [GitHub - .NET Aspire Issues](https://github.com/dotnet/aspire/issues)
- [Azure Community Support](https://docs.microsoft.com/en-us/answers/topics/azure-container-apps.html)

### Tools and Utilities

- [Azure Resource Explorer](https://resources.azure.com/)
- [Kudu Console](https://github.com/projectkudu/kudu/wiki)
- [Application Insights Analytics](https://analytics.applicationinsights.io/)

---

_This troubleshooting guide is continuously updated based on common issues encountered in the aspire-demo89x project. Please contribute by reporting new issues and solutions._
