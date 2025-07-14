# GitHub Environments Setup Guide

This document describes how to set up GitHub Environments for the aspire-demo89x project to support multi-environment deployments with custom Azure resource naming.

## 🌍 Required GitHub Environments

You need to create the following environments in your GitHub repository:

### Navigation

Go to: **Repository Settings → Environments → New environment**

## 1. Dev Environment

**Environment Name:** `Dev`

### Environment Variables

| Variable           | Value            | Description                            |
| ------------------ | ---------------- | -------------------------------------- |
| `AZURE_ENV_NAME`   | `aspire-dev-001` | Base environment name for azd          |
| `AZURE_LOCATION`   | `eastus`         | Primary Azure region                   |
| `AZURE_ENV_SUFFIX` | `D`              | Environment suffix for resource naming |

### Environment Secrets (if needed)

- Inherit from repository-level secrets
- No additional secrets required if using federated credentials

## 2. Test Environment

**Environment Name:** `Test`

### Environment Variables

| Variable           | Value             | Description                            |
| ------------------ | ----------------- | -------------------------------------- |
| `AZURE_ENV_NAME`   | `aspire-test-001` | Base environment name for azd          |
| `AZURE_LOCATION`   | `eastus`          | Primary Azure region                   |
| `AZURE_ENV_SUFFIX` | `T`               | Environment suffix for resource naming |

## 📋 Repository-Level Secrets

These should be configured at **Repository Settings → Secrets and variables → Actions → Secrets**:

| Secret                           | Description                       | Required                   |
| -------------------------------- | --------------------------------- | -------------------------- |
| `AZURE_CLIENT_ID`                | Service Principal Client ID       | ✅ Yes                     |
| `AZURE_TENANT_ID`                | Azure Tenant ID                   | ✅ Yes                     |
| `AZURE_SUBSCRIPTION_ID`          | Azure Subscription ID             | ✅ Yes                     |
| `AZURE_CREDENTIALS`              | Service Principal JSON (optional) | ❌ No (if using federated) |
| `AZD_INITIAL_ENVIRONMENT_CONFIG` | azd environment config (optional) | ❌ No                      |

## 🎯 Expected Resource Naming

With this setup, your Azure resources will be named as follows:

### Dev Environment (eastus)

```text
Resource Group: rg-Dev-eastus
Managed Identity: sv-mi-D
Container Registry: svacrd
Log Analytics: sv-law-D
Container Apps Environment: sv-cae-D
Redis Cache: sv-cache-D
```

### Test Environment (eastus)

```text
Resource Group: rg-Test-eastus
Managed Identity: sv-mi-T
Container Registry: svacrt
Log Analytics: sv-law-T
Container Apps Environment: sv-cae-T
Redis Cache: sv-cache-T
```

### Multi-Region Support

If deploying to multiple regions (eastus, centralus), you'll get:

- `rg-Dev-eastus` and `rg-Dev-centralus`
- `rg-Test-eastus` and `rg-Test-centralus`

## 🔧 How to Set Up

### Step 1: Create Environment

1. Go to your repository on GitHub
2. Click **Settings** tab
3. Click **Environments** in the left sidebar
4. Click **New environment**
5. Enter environment name: `Dev`
6. Click **Configure environment**

### Step 2: Add Environment Variables

1. In the environment configuration, scroll to **Environment variables**
2. Click **Add variable**
3. Add each variable from the tables above

### Step 3: Repeat for Test Environment

Repeat steps 1-2 for the `Test` environment with the appropriate values.

## 🚀 Workflow Integration

The workflows are now configured to:

1. **Auto-select environment suffix** based on the matrix environment name
2. **Use consistent working directories** across all workflows
3. **Generate proper resource group names** following the pattern `rg-{Environment}-{Region}`
4. **Pass environment suffix to azd** for custom resource naming

## ✅ Verification

After setting up the environments, you can verify the configuration by:

1. **Manual workflow run**: Go to Actions → Aspire Demo .NET 8 Aspire 9.x Main → Run workflow
2. **Check deployment logs** for correct environment variable values
3. **Verify Azure resources** are created with the expected naming convention

## 🔍 Troubleshooting

### Common Issues

#### Environment not found

- Ensure environment names match exactly: `Dev`, `Test` (case-sensitive)

#### Missing variables

- Check that all required environment variables are set in each environment

#### Wrong resource names

- Verify `AZURE_ENV_SUFFIX` is set correctly in each environment
- Check that the workflows are passing the environment-suffix parameter

### Debug Commands

To debug environment variable values, check the "Print Environment Variables" step in the deployment workflow logs.

---

Last updated: July 14, 2025
