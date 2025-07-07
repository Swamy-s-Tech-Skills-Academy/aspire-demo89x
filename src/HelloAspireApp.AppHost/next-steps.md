# Next Steps after `azd init`

## Table of Contents

1. [Next Steps](#next-steps)
2. [Custom Resource Naming](#custom-resource-naming)
3. [What was added](#what-was-added)
4. [Billing](#billing)
5. [Troubleshooting](#troubleshooting)

## Next Steps

### Provision infrastructure and deploy application code with custom naming

**⚠️ Important**: This project uses a custom resource naming convention. Instead of running `azd up` directly, use the provided deployment script to ensure proper naming:

```powershell
# For Development environment (default)
.\Deploy-WithCustomNames.ps1
azd up

# For Production environment
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "P"
azd up

# For Test environment
.\Deploy-WithCustomNames.ps1 -EnvironmentSuffix "T"
azd up
```

This script automatically:

- Sets up environment variables for custom naming
- Generates infrastructure with `azd infra generate --force`
- Applies enterprise naming conventions to all Azure resources
- Provides a summary of resource names for verification

**Manual Method (Not Recommended)**: If you run `azd provision` or `azd up` directly without the script, your resources will use default azd naming instead of the custom `sv-*-{env}` convention.

To troubleshoot any issues, see [troubleshooting](#troubleshooting).

## Custom Resource Naming

This project implements an enterprise-grade Azure resource naming convention using the `sv-*-{env}` pattern:

### Resource Naming Examples

| Environment     | Redis Cache  | Container Registry | Log Analytics | Container Apps Env | Managed Identity |
| --------------- | ------------ | ------------------ | ------------- | ------------------ | ---------------- |
| Development (D) | `sv-cache-D` | `svacrd`           | `sv-law-D`    | `sv-cae-D`         | `sv-mi-D`        |
| Production (P)  | `sv-cache-P` | `svacrp`           | `sv-law-P`    | `sv-cae-P`         | `sv-mi-P`        |

### How It Works

The solution uses a **two-part approach**:

1. **FixedNameInfrastructureResolver**: Automatically names Aspire-managed resources (Redis, Storage, etc.)
2. **PowerShell Post-Processing**: Updates core infrastructure resource names in generated Bicep files

### Environment Variables

Set `AZURE_ENV_SUFFIX` to control the environment suffix:

- `D` = Development
- `T` = Test
- `S` = Staging
- `P` = Production

The `Deploy-WithCustomNames.ps1` script handles this automatically.

### Configure CI/CD pipeline

Run `azd pipeline config -e <environment name>` to configure the deployment pipeline to connect securely to Azure. An environment name is specified here to configure the pipeline with a different environment for isolation purposes. Run `azd env list` and `azd env set` to reselect the default environment after this step.

- Deploying with `GitHub Actions`: Select `GitHub` when prompted for a provider. If your project lacks the `azure-dev.yml` file, accept the prompt to add it and proceed with pipeline configuration.

- Deploying with `Azure DevOps Pipeline`: Select `Azure DevOps` when prompted for a provider. If your project lacks the `azure-dev.yml` file, accept the prompt to add it and proceed with pipeline configuration.

## What was added

### Infrastructure configuration

To describe the infrastructure and application, an `azure.yaml` was added with the following directory structure:

```yaml
- azure.yaml # azd project configuration
```

This file contains a single service, which references your project's App Host. When needed, `azd` generates the required infrastructure as code in memory and uses it.

If you would like to see or modify the infrastructure that `azd` uses, run `azd infra gen` to generate it to disk.

If you do this, some additional directories will be created:

```yaml
- infra/            # Infrastructure as Code (bicep) files
  - main.bicep      # main deployment module
  - resources.bicep # resources shared across your application's services
```

In addition, for each project resource referenced by your app host, a `containerApp.tmpl.yaml` file will be created in a directory named `manifests` next the project file. This file contains the infrastructure as code for running the project on Azure Container Apps.

_Note_: Once you have generated your infrastructure to disk, those files are the source of truth for azd. Any changes made to `azure.yaml` or your App Host will not be reflected in the infrastructure until you regenerate it with `azd infra gen` again. It will prompt you before overwriting files. You can pass `--force` to force `azd infra gen` to overwrite the files without prompting.

## Billing

Visit the _Cost Management + Billing_ page in Azure Portal to track current spend. For more information about how you're billed, and how you can monitor the costs incurred in your Azure subscriptions, visit [billing overview](https://learn.microsoft.com/azure/developer/intro/azure-developer-billing).

## Troubleshooting

Q: I visited the service endpoint listed, and I'm seeing a blank page, a generic welcome page, or an error page.

A: Your service may have failed to start, or it may be missing some configuration settings. To investigate further:

1. Run `azd show`. Click on the link under "View in Azure Portal" to open the resource group in Azure Portal.
2. Navigate to the specific Container App service that is failing to deploy.
3. Click on the failing revision under "Revisions with Issues".
4. Review "Status details" for more information about the type of failure.
5. Observe the log outputs from Console log stream and System log stream to identify any errors.
6. If logs are written to disk, use _Console_ in the navigation to connect to a shell within the running container.

For more troubleshooting information, visit [Container Apps troubleshooting](https://learn.microsoft.com/azure/container-apps/troubleshooting).

### Additional information

For additional information about setting up your `azd` project, visit our official [docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-convert).
