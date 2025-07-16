# GitHub Actions Workflows Documentation

This document describes the GitHub Actions workflows used in the aspire-demo89x project for automated building, testing, and deployment.

## 📋 Table of Contents

- [Overview](#overview)
- [Main Workflow](#main-workflow)
- [Build & Test Workflow](#build--test-workflow)
- [Deployment Workflow](#deployment-workflow)
- [Setup and Configuration](#setup-and-configuration)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

## 🔄 Overview

The project uses three main GitHub Actions workflows:

1. **`demo89x-main.yaml`** - Main orchestration workflow with staged deployment
2. **`demo89x-build-test.yaml`** - Reusable workflow for building, testing, and code coverage
3. **`demo89x-deploy.yaml`** - Reusable deployment workflow for Azure deployment

## 🎯 Main Workflow (demo89x-main.yaml)

### Purpose

The main workflow orchestrates the entire CI/CD pipeline with staged deployment from Dev to Test environment.

### Workflow Structure

```yaml
name: Aspire Demo .NET 8 Aspire 9.x Main

on:
  workflow_dispatch:
  push:
    branches:
      - main

jobs:
  build-and-test:
    uses: ./.github/workflows/demo89x-build-test.yaml

  deploy-dev:
    needs: build-and-test
    strategy:
      matrix:
        include:
          - environment: Dev
            region: eastus
    uses: ./.github/workflows/demo89x-deploy.yaml

  deploy-test:
    needs: deploy-dev # Wait for Dev deployment
    strategy:
      matrix:
        include:
          - environment: Test
            region: eastus
    uses: ./.github/workflows/demo89x-deploy.yaml
```

### Key Features

- **Staged Deployment**: Deploy to Dev first, then Test after approval
- **Single Region**: Currently configured for eastus only
- **Matrix Strategy**: Extensible for multi-region deployment
- **Dependency Management**: Test deployment waits for Dev completion

## 🧪 Reusable Build & Test Workflow

**File:** `.github/workflows/demo89x-build-test.yaml`

### Purpose

A reusable workflow that can be called from other workflows to build .NET solutions, run tests, and generate code coverage reports.

### Inputs

| Input            | Description                                        | Required | Default   |
| ---------------- | -------------------------------------------------- | -------- | --------- |
| `project-name`   | The name of the project (used for artifact naming) | ✅ Yes   | -         |
| `solution-path`  | Path to the solution file (.sln)                   | ✅ Yes   | -         |
| `dotnet-version` | .NET version to use                                | ❌ No    | `"9.x.x"` |

### Features

- ✅ **Multi-format code coverage** - Generates coverage in Cobertura, OpenCover, and JSON formats
- ✅ **Auto-discovery** - Automatically finds and runs all `*.Tests.csproj` projects
- ✅ **Aspire support** - Installs .NET Aspire workload and Azure Developer CLI
- ✅ **Artifact upload** - Uploads test results and coverage reports
- ✅ **Codecov integration** - Automatically uploads coverage to Codecov (for public repos)
- ✅ **Fail-fast** - Stops execution if any test fails

### Workflow Steps

1. **Environment Setup**

   - Checkout code
   - Setup .NET SDK
   - Install Azure Developer CLI (azd)
   - Install .NET Aspire workload

2. **Build Process**

   - Restore NuGet packages
   - Build solution (no-restore for performance)

3. **Test Execution**

   - Auto-discover test projects (`*.Tests.csproj`)
   - Run tests with multiple coverage formats
   - Generate TRX test result files
   - Fail workflow if any tests fail

4. **Artifact Management**
   - Upload test results (always runs, even on failure)
   - Upload code coverage reports
   - Send coverage to Codecov

### Usage Example

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: ./.github/workflows/demo89x-build-test.yaml
    with:
      project-name: "aspire-demo89x"
      solution-path: "aspire-demo89x.sln"
      dotnet-version: "9.x.x"
```

### Generated Artifacts

```
TestResults-{project-name}/
├── {TestProject1}/
│   ├── *.trx                    # Test result files
│   └── CoverageResults/
│       ├── coverage.cobertura   # Cobertura format
│       ├── coverage.opencover   # OpenCover format
│       └── coverage.json        # JSON format
└── {TestProject2}/
    └── ...
```

## 🚀 Azure Deployment Workflow

**File:** `.github/workflows/deploy-to-azure.yml`

### Purpose

Deploys the .NET Aspire application to Azure using Azure Developer CLI with custom resource naming conventions.

### Environment Support

The workflow uses GitHub Environments for different deployment targets:

| Environment | Resources Named With | Example Resources                 |
| ----------- | -------------------- | --------------------------------- |
| `dev`       | Suffix: `D`          | `sv-mi-D`, `sv-cache-D`, `svacrd` |
| `test`      | Suffix: `T`          | `sv-mi-T`, `sv-cache-T`, `svacrt` |
| `staging`   | Suffix: `S`          | `sv-mi-S`, `sv-cache-S`, `svacrs` |

### Environment Variables

| Variable                | Source               | Purpose                                            |
| ----------------------- | -------------------- | -------------------------------------------------- |
| `AZURE_CLIENT_ID`       | Repository Secret    | Azure service principal client ID                  |
| `AZURE_TENANT_ID`       | Repository Secret    | Azure tenant ID                                    |
| `AZURE_SUBSCRIPTION_ID` | Repository Secret    | Azure subscription ID                              |
| `AZURE_CREDENTIALS`     | Repository Secret    | Azure service principal credentials                |
| `AZURE_ENV_NAME`        | Environment Variable | Environment-specific name (e.g., `aspire-dev-001`) |
| `AZURE_LOCATION`        | Environment Variable | Azure region (e.g., `eastus`)                      |
| `AZURE_ENV_SUFFIX`      | Environment Variable | Resource naming suffix (`D`/`T`/`S`/`P`)           |

### Workflow Steps

1. **Setup**

   - Checkout code
   - Install Azure Developer CLI
   - Setup .NET SDK (8.x and 9.x)

2. **Authentication**

   - Login to Azure using federated credentials
   - No password/secret required for authentication

3. **Infrastructure & Deployment**
   - Provision Azure resources with custom naming
   - Deploy application to provisioned resources

### Custom Resource Naming

The workflow implements enterprise-grade resource naming using environment-specific suffixes:

```
Resource Type                 Example Name (Dev)
─────────────────────────────────────────────
Managed Identity             sv-mi-D
Container Registry           svacrd
Log Analytics Workspace     sv-law-D
Container Apps Environment   sv-cae-D
Redis Cache                  sv-cache-D
```

## ⚙️ Setup and Configuration

### 1. Repository Secrets

Configure these secrets in **Settings → Secrets and variables → Actions**:

```
AZURE_CLIENT_ID         # Service principal client ID
AZURE_TENANT_ID         # Azure tenant ID
AZURE_SUBSCRIPTION_ID   # Azure subscription ID
AZURE_CREDENTIALS       # Service principal JSON (optional)
```

### 2. GitHub Environments

Create environments in **Settings → Environments**:

#### Dev Environment

```
Name: dev
Variables:
  AZURE_ENV_NAME: aspire-dev-001
  AZURE_LOCATION: eastus
  AZURE_ENV_SUFFIX: D
```

#### Test Environment

```
Name: test
Variables:
  AZURE_ENV_NAME: aspire-test-001
  AZURE_LOCATION: eastus
  AZURE_ENV_SUFFIX: T
```

#### Staging Environment

```
Name: staging
Variables:
  AZURE_ENV_NAME: aspire-staging-001
  AZURE_LOCATION: eastus
  AZURE_ENV_SUFFIX: S
```

### 3. Codecov Setup (Optional)

For private repositories or enhanced features:

1. Sign up at [codecov.io](https://codecov.io)
2. Add your repository
3. Copy the repository token
4. Add as repository secret: `CODECOV_TOKEN`

## 📖 Usage Examples

### Basic CI/CD Pipeline

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  # Build and test
  test:
    uses: ./.github/workflows/demo89x-build-test.yaml
    with:
      project-name: "aspire-demo89x"
      solution-path: "aspire-demo89x.sln"

  # Deploy to dev (only on main branch)
  deploy-dev:
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/deploy-to-azure.yml
    environment: dev
```

### Multi-Environment Deployment

```yaml
name: Multi-Environment Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: "Environment to deploy to"
        required: true
        type: choice
        options:
          - dev
          - test
          - staging

jobs:
  deploy:
    uses: ./.github/workflows/deploy-to-azure.yml
    environment: ${{ github.event.inputs.environment }}
```

## 🔍 Troubleshooting

### Common Issues

#### Build Failures

**Issue:** `dotnet restore` fails

```bash
# Solution: Check .NET version compatibility
dotnet --version
# Ensure project targets compatible framework
```

**Issue:** Aspire workload installation fails

```bash
# Solution: Update to latest .NET SDK
dotnet workload update
dotnet workload install aspire
```

#### Test Failures

**Issue:** Tests fail but run locally

```bash
# Check test project dependencies
# Ensure all required services are mocked
# Review test environment setup
```

**Issue:** Code coverage not generated

```bash
# Ensure Coverlet.MSBuild package is installed
dotnet add package coverlet.msbuild
```

#### Deployment Failures

**Issue:** Azure authentication fails

```bash
# Verify service principal permissions
# Check federated credential configuration
# Ensure correct tenant/subscription IDs
```

**Issue:** Resource naming conflicts

```bash
# Verify environment suffix configuration
# Check for existing resources with same names
# Review main.parameters.json configuration
```

### Debug Tips

1. **Enable verbose logging:**

   ```yaml
   - name: Debug Azure CLI
     run: az config set core.only_show_errors=false
   ```

2. **Check environment variables:**

   ```yaml
   - name: Print Environment Variables
     run: env | grep AZURE
   ```

3. **Validate Bicep templates:**
   ```bash
   az bicep build --file infra/main.bicep
   ```

## 📚 Additional Resources

- [Azure Developer CLI Documentation](https://docs.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [.NET Aspire Documentation](https://docs.microsoft.com/en-us/dotnet/aspire/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Codecov Documentation](https://docs.codecov.io/)

---

_Last updated: July 14, 2025_
