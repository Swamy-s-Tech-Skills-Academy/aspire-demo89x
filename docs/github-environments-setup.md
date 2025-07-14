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

### Environment Protection Rules

⚠️ **Important**: Configure manual approval for Test environment:

1. In the Test environment settings, go to **Protection rules**
2. Check **Required reviewers**
3. Add yourself or your team members as required reviewers
4. This ensures Test deployments require manual approval after Dev deployment completes

### Test Environment Variables

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

### Step 3: Configure Test Environment with Approval

1. Create the `Test` environment following steps 1-2
2. Add the environment variables for Test
3. **Enable Protection Rules for Test environment:**
   - Go to Test environment settings
   - Scroll to **Environment protection rules**
   - Check **Required reviewers**
   - Add team members who can approve Test deployments
   - Save the protection rules

## 🚀 Workflow Integration

The workflows are now configured with a **staged deployment approach**:

### Deployment Sequence

1. **Build & Test** → All code is built and tested first
2. **Deploy to Dev** → Automatic deployment to both Dev regions (eastus, centralus)
3. **Deploy to Test** → **Requires manual approval** + waits for Dev deployment completion

### Features

1. **Environment-driven configuration** based on GitHub Environment variables
2. **Multi-region support** for both Dev and Test environments
3. **Staged deployments** with Test requiring Dev success
4. **Manual approval gates** for Test environment
5. **Custom resource naming** following `sv-*-{env}` pattern

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
