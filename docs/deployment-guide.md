# Deployment Guide

This guide provides step-by-step instructions for deploying the aspire-demo89x application to Azure using various deployment methods.

## 🚀 Deployment Methods

### 1. Local Development Deployment

- Quick local deployment using Azure Developer CLI
- Suitable for development and testing
- Manual configuration required

### 2. GitHub Actions CI/CD

- Automated deployment pipeline
- Multi-environment support with approval gates
- Recommended for production use

### 3. Manual Azure CLI Deployment

- Direct Azure CLI commands
- Advanced scenarios and troubleshooting
- Full control over deployment process

## 🔧 Prerequisites

### Required Tools

- **.NET 8.0 SDK** - [Download](https://dotnet.microsoft.com/download/dotnet/8.0)
- **Azure Developer CLI (azd)** - [Install Guide](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
- **Azure CLI** - [Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Docker Desktop** - [Download](https://www.docker.com/products/docker-desktop)
- **Git** - [Download](https://git-scm.com/downloads)

### Azure Requirements

- **Azure Subscription** with appropriate permissions
- **Service Principal** or **Managed Identity** for authentication
- **Resource Group** creation permissions
- **Container Apps** and **Container Registry** access

### Development Environment

```bash
# Verify prerequisites
dotnet --version          # Should be 8.0.x or higher
azd version              # Should be 1.5.0 or higher
az --version             # Should be 2.50.0 or higher
docker --version         # Should be 20.10.0 or higher
```

## 🏠 Local Development Deployment

### Step 1: Clone and Setup

```bash
# Clone repository
git clone https://github.com/Swamy-s-Tech-Skills-Academy/aspire-demo89x.git
cd aspire-demo89x

# Navigate to AppHost directory
cd src/HelloAspireApp.AppHost

# Install .NET Aspire workload
dotnet workload install aspire
```

### Step 2: Azure Authentication

```bash
# Login to Azure
azd auth login
az login

# Set subscription (if multiple subscriptions)
az account set --subscription "<your-subscription-id>"
```

### Step 3: Environment Configuration

```bash
# Create new azd environment
azd env new aspire-dev-001

# Set environment variables
azd env set AZURE_LOCATION eastus
azd env set AZURE_ENV_SUFFIX D
azd env set AZURE_RESOURCE_GROUP rg-Dev-eastus

# Verify configuration
azd env get-values
```

### Step 4: Deploy

```bash
# Deploy infrastructure and application
azd up

# Or deploy separately
azd provision  # Infrastructure only
azd deploy     # Application only
```

### Step 5: Verify Deployment

```bash
# Check deployment status
azd show

# Get application endpoints
azd show --output json | jq '.services[].bindings[]'
```

## 🔄 GitHub Actions CI/CD Deployment

### Step 1: Repository Setup

1. **Fork or clone** the repository to your GitHub account
2. **Enable GitHub Actions** in repository settings
3. **Configure repository secrets** (see [GitHub Environments Setup](github-environments-setup.md))

### Step 2: Create GitHub Environments

Navigate to **Repository Settings → Environments**:

#### Dev Environment

- **Name**: `Dev`
- **Protection Rules**: None (automatic deployment)
- **Variables**:
  ```
  AZURE_ENV_NAME = aspire-dev-001
  AZURE_LOCATION = eastus
  AZURE_ENV_SUFFIX = D
  ```

#### Test Environment

- **Name**: `Test`
- **Protection Rules**: Required reviewers (manual approval)
- **Variables**:
  ```
  AZURE_ENV_NAME = aspire-test-001
  AZURE_LOCATION = eastus
  AZURE_ENV_SUFFIX = T
  ```

### Step 3: Configure Repository Secrets

Add these secrets in **Repository Settings → Secrets and variables → Actions**:

| Secret Name             | Description                 | Required |
| ----------------------- | --------------------------- | -------- |
| `AZURE_CLIENT_ID`       | Service Principal Client ID | Yes      |
| `AZURE_TENANT_ID`       | Azure Tenant ID             | Yes      |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID       | Yes      |
| `AZURE_CREDENTIALS`     | Service Principal JSON      | Optional |

### Step 4: Trigger Deployment

```bash
# Push to main branch
git push origin main

# Or trigger manually
# Go to Actions tab → "Aspire Demo .NET 8 Aspire 9.x Main" → "Run workflow"
```

### Step 5: Monitor Deployment

1. **View Progress**: Actions tab → Running workflow
2. **Dev Deployment**: Automatic after build/test passes
3. **Test Deployment**: Requires manual approval
4. **Approval Process**: GitHub will request approval for Test environment

### Step 6: Verify Multi-Environment Deployment

```bash
# Check Dev environment
az resource list --resource-group rg-Dev-eastus --output table

# Check Test environment (after approval)
az resource list --resource-group rg-Test-eastus --output table
```

## 🛠️ Manual Azure CLI Deployment

### Step 1: Prepare Environment

```bash
# Set variables
ENVIRONMENT_NAME="aspire-manual-001"
LOCATION="eastus"
ENV_SUFFIX="M"
RESOURCE_GROUP="rg-Manual-eastus"
SUBSCRIPTION_ID="your-subscription-id"

# Login and set subscription
az login
az account set --subscription $SUBSCRIPTION_ID
```

### Step 2: Create Resource Group

```bash
# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags azd-env-name=$ENVIRONMENT_NAME
```

### Step 3: Deploy Infrastructure

```bash
# Deploy Bicep template
az deployment sub create \
  --location $LOCATION \
  --template-file src/HelloAspireApp.AppHost/infra/main.bicep \
  --parameters \
    environmentName=$ENVIRONMENT_NAME \
    location=$LOCATION \
    environmentSuffix=$ENV_SUFFIX \
    resourceGroupName=$RESOURCE_GROUP
```

### Step 4: Build and Push Container Images

```bash
# Build application
cd src/HelloAspireApp.AppHost
dotnet build

# Get container registry name
REGISTRY_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)

# Login to container registry
az acr login --name $REGISTRY_NAME

# Build and push images (this is typically handled by azd)
# Manual container building requires additional steps
```

### Step 5: Deploy Container Apps

```bash
# Deploy using azd (recommended)
azd env new $ENVIRONMENT_NAME
azd env set AZURE_LOCATION $LOCATION
azd env set AZURE_ENV_SUFFIX $ENV_SUFFIX
azd env set AZURE_RESOURCE_GROUP $RESOURCE_GROUP
azd deploy
```

## 🌍 Multi-Region Deployment

### Configuration for Multiple Regions

```yaml
# GitHub Actions matrix strategy
strategy:
  matrix:
    include:
      - environment: Dev
        region: eastus
      - environment: Dev
        region: centralus
      - environment: Test
        region: eastus
      - environment: Test
        region: centralus
```

### Region-Specific Environment Variables

**Dev East US:**

```
AZURE_ENV_NAME = aspire-dev-eastus-001
AZURE_LOCATION = eastus
AZURE_ENV_SUFFIX = D
```

**Dev Central US:**

```
AZURE_ENV_NAME = aspire-dev-centralus-001
AZURE_LOCATION = centralus
AZURE_ENV_SUFFIX = D
```

### Multi-Region Deployment Commands

```bash
# Deploy to East US
azd env new aspire-dev-eastus-001
azd env set AZURE_LOCATION eastus
azd env set AZURE_ENV_SUFFIX D
azd env set AZURE_RESOURCE_GROUP rg-Dev-eastus
azd up

# Deploy to Central US
azd env new aspire-dev-centralus-001
azd env set AZURE_LOCATION centralus
azd env set AZURE_ENV_SUFFIX D
azd env set AZURE_RESOURCE_GROUP rg-Dev-centralus
azd up
```

## 🔍 Deployment Verification

### Health Checks

```bash
# Check resource group
az group show --name $RESOURCE_GROUP

# List all resources
az resource list --resource-group $RESOURCE_GROUP --output table

# Check Container Apps status
az containerapp list --resource-group $RESOURCE_GROUP --output table

# Check Container Registry
az acr list --resource-group $RESOURCE_GROUP --output table

# Check Redis Cache
az redis list --resource-group $RESOURCE_GROUP --output table
```

### Application Health Verification

```bash
# Get application endpoints
azd show --output json | jq '.services[].bindings[]'

# Test web frontend
curl -I https://your-web-app-url

# Test API service
curl -I https://your-api-service-url/weatherforecast

# Check Container Apps logs
az containerapp logs show \
  --name your-container-app-name \
  --resource-group $RESOURCE_GROUP
```

### Monitoring and Alerts

```bash
# Check Log Analytics workspace
az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name sv-law-$ENV_SUFFIX-use

# Query recent logs
az monitor log-analytics query \
  --workspace sv-law-$ENV_SUFFIX-use \
  --analytics-query "ContainerAppConsoleLogs_CL | limit 50"
```

## 🔄 Environment Management

### Environment Lifecycle

1. **Development**: Continuous deployment from main branch
2. **Testing**: Manual approval required
3. **Staging**: Scheduled deployments
4. **Production**: Change-controlled deployments

### Environment Promotion

```bash
# Promote from Dev to Test
# 1. Merge dev changes to main
# 2. GitHub Actions will deploy to Dev automatically
# 3. Approve Test deployment manually
# 4. Monitor Test environment

# Promote from Test to Production
# 1. Create production environment
# 2. Update GitHub Actions workflow
# 3. Deploy with proper approvals
```

### Environment Cleanup

```bash
# Remove specific environment
azd down

# Remove resource group
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Clean up azd environments
azd env list
azd env delete <environment-name>
```

## 🐛 Troubleshooting Deployments

### Common Issues

1. **Authentication Failures**

   ```bash
   # Re-authenticate
   azd auth login
   az login
   ```

2. **Resource Naming Conflicts**

   ```bash
   # Check existing resources
   az resource list --query "[?contains(name, 'sv-')]"

   # Use different environment suffix
   azd env set AZURE_ENV_SUFFIX X
   ```

3. **Quota Limitations**

   ```bash
   # Check quota usage
   az vm list-usage --location eastus --output table
   ```

4. **Network Issues**
   ```bash
   # Check Container Apps connectivity
   az containerapp show \
     --name your-app-name \
     --resource-group $RESOURCE_GROUP \
     --query properties.configuration.ingress
   ```

### Debugging Steps

1. **Check azd logs**

   ```bash
   azd show --output json
   ```

2. **Validate Bicep templates**

   ```bash
   az bicep build --file infra/main.bicep
   ```

3. **Review deployment history**

   ```bash
   az deployment group list --resource-group $RESOURCE_GROUP
   ```

4. **Check resource status**
   ```bash
   az resource list --resource-group $RESOURCE_GROUP --output table
   ```

### Getting Help

- **Azure Documentation**: [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)
- **GitHub Issues**: Create issues in the repository
- **Azure Support**: For subscription-related issues
- **Community**: Stack Overflow with `azure-container-apps` tag

## 📋 Deployment Checklist

### Pre-Deployment

- [ ] Prerequisites installed and configured
- [ ] Azure subscription access verified
- [ ] Service Principal created and configured
- [ ] GitHub secrets configured (for CI/CD)
- [ ] Environment variables set
- [ ] Bicep templates validated

### During Deployment

- [ ] Monitor deployment progress
- [ ] Check for any errors or warnings
- [ ] Verify resource creation
- [ ] Test application endpoints
- [ ] Review logs for issues

### Post-Deployment

- [ ] Application health checks passed
- [ ] All services responding correctly
- [ ] Monitoring and alerting configured
- [ ] Documentation updated
- [ ] Team notifications sent

## 🎯 Best Practices

### Security

1. **Use Managed Identity**: Avoid storing credentials
2. **Network Security**: Configure proper network boundaries
3. **RBAC**: Implement role-based access control
4. **Secrets Management**: Use Azure Key Vault
5. **Regular Updates**: Keep dependencies updated

### Performance

1. **Resource Sizing**: Right-size resources for workload
2. **Scaling**: Configure auto-scaling rules
3. **Monitoring**: Implement comprehensive monitoring
4. **Caching**: Use Redis for performance optimization
5. **CDN**: Consider CDN for static content

### Reliability

1. **Health Checks**: Implement robust health checks
2. **Redundancy**: Deploy across multiple regions
3. **Backup**: Regular backup procedures
4. **Disaster Recovery**: Plan for disaster recovery
5. **Testing**: Regular deployment testing

---

_This deployment guide ensures successful and reliable deployments of the aspire-demo89x application across all environments._
