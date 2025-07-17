# Aspire Demo89x Documentation

Welcome to the comprehensive documentation for the **aspire-demo89x** project - a .NET Aspire application with enterprise-grade Azure resource naming conventions and automated CI/CD deployment.

## 📚 Documentation Index

### 🚀 Getting Started

- [Project Overview](#project-overview)
- [Quick Start Guide](#quick-start-guide)
- [Local Development Setup](#local-development-setup)

### 🏗️ Architecture & Design

- [Architecture Overview](architecture-overview.md)
- [Resource Naming Convention](resource-naming-convention.md)
- [Infrastructure as Code](infrastructure-as-code.md)

### 🔧 CI/CD & Deployment

- [GitHub Actions Workflows](github-actions-workflows.md)
- [GitHub Environments Setup](github-environments-setup.md)
- [Deployment Guide](deployment-guide.md)
- [Environment Management](environment-management.md)

### 📖 Developer Guides

- [Developer Guide](developer-guide.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Configuration Reference](configuration-reference.md)

### 🔐 Security & Best Practices

- [Security Guidelines](security-guidelines.md)
- [Best Practices](best-practices.md)

---

## 🎯 Project Overview

The **aspire-demo89x** project is a .NET Aspire application that demonstrates:

- **Enterprise-grade Azure resource naming** with region-specific abbreviations
- **Automated infrastructure deployment** using Azure Developer CLI (azd)
- **Multi-environment CI/CD** with GitHub Actions
- **Staged deployment pipeline** (Dev → Test with manual approval)
- **Custom infrastructure resolvers** for fixed Azure resource names

## 🏛️ Architecture Components

### Core Services

- **API Service** (`HelloAspireApp.ApiService`) - RESTful API backend
- **Web Frontend** (`HelloAspireApp.Web`) - Blazor Server web application
- **App Host** (`HelloAspireApp.AppHost`) - .NET Aspire orchestrator

### Azure Resources

- **Azure Container Apps** - Hosting the containerized applications
- **Azure Container Registry** - Container image storage
- **Azure Redis Cache** - Distributed caching
- **Azure Log Analytics** - Centralized logging
- **Azure Managed Identity** - Security and authentication

## 🚀 Quick Start Guide

### Prerequisites

- .NET 8.0 SDK
- Azure Developer CLI (azd)
- Azure subscription
- GitHub repository with proper secrets

### Local Development

```bash
# Clone the repository
git clone https://github.com/Swamy-s-Tech-Skills-Academy/aspire-demo89x.git
cd aspire-demo89x

# Navigate to AppHost
cd src/HelloAspireApp.AppHost

# Deploy infrastructure (one-time setup)
azd provision

# Deploy application
azd deploy

# Or deploy both together
azd up
```

### GitHub Actions Deployment

1. Set up [GitHub Environments](github-environments-setup.md)
2. Configure repository secrets
3. Push to main branch or trigger workflow manually

## 🌟 Key Features

### 🏷️ Smart Resource Naming

- **Environment-aware**: Resources tagged with environment suffix (D/T/S/P)
- **Region-specific**: Resources include region abbreviations (use, usc, etc.)
- **Consistent**: All resources follow `sv-{service}-{env}-{region}` pattern

### 🔄 Staged Deployment

- **Dev Environment**: Automatic deployment to East US and Central US regions
- **Test Environment**: Manual approval required before deployment
- **Production Ready**: Extensible for Staging/Production environments
- **Multi-Region Support**: Dev environment tests across multiple regions

### 🛡️ Security Features

- **Managed Identity**: No stored secrets in application code
- **Federated Credentials**: Secure GitHub Actions authentication
- **Resource-level RBAC**: Fine-grained access control

## 📋 Resource Naming Examples

### Dev Environment (Multi-Region)

**East US:**

```text
Resource Group: rg-Dev-eastus
Managed Identity: sv-mi-D-use
Container Registry: svacrduse
Log Analytics: sv-law-D-use
Container Apps Env: sv-cae-D-use
Redis Cache: sv-cache-D-use
```

**Central US:**

```text
Resource Group: rg-Dev-centralus
Managed Identity: sv-mi-D-usc
Container Registry: svacrdusc
Log Analytics: sv-law-D-usc
Container Apps Env: sv-cae-D-usc
Redis Cache: sv-cache-D-usc
```

### Test Environment (East US)

```text
Resource Group: rg-Test-eastus
Managed Identity: sv-mi-T-use
Container Registry: svacrtuse
Log Analytics: sv-law-T-use
Container Apps Env: sv-cae-T-use
Redis Cache: sv-cache-T-use
```

## 🔗 Related Links

- [.NET Aspire Documentation](https://learn.microsoft.com/en-us/dotnet/aspire/)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:

- Create an issue in the GitHub repository
- Review the [troubleshooting guide](troubleshooting.md)
- Check the [FAQ section](troubleshooting.md#faq)

---

_Last updated: July 15, 2025_
