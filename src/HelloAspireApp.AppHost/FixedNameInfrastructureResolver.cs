using Azure.Provisioning;
using Azure.Provisioning.AppContainers;
using Azure.Provisioning.ContainerRegistry;
using Azure.Provisioning.OperationalInsights;
using Azure.Provisioning.Primitives;
using Azure.Provisioning.Redis;
using Azure.Provisioning.Storage;
using Microsoft.Extensions.Configuration;

namespace HelloAspireApp.AppHost;

public sealed class FixedNameInfrastructureResolver(IConfiguration configuration) : InfrastructureResolver
{
    private readonly IConfiguration _configuration = configuration;
    private const string UniqueNamePrefix = "sv";

    public override void ResolveProperties(ProvisionableConstruct construct, ProvisioningBuildOptions options)
    {
        // Get environment suffix from configuration, default to "D" (Development)
        string environmentSuffix = _configuration["AZURE_ENV_SUFFIX"] ?? "D";

        switch (construct)
        {
            case StorageAccount storageAccount:
                storageAccount.Name = $"{UniqueNamePrefix}{storageAccount.BicepIdentifier.ToLowerInvariant()}{environmentSuffix.ToLower()}";
                break;

            case Azure.Provisioning.Redis.RedisResource redisCache:
                redisCache.Name = $"{UniqueNamePrefix}-{redisCache.BicepIdentifier.ToLowerInvariant()}-{environmentSuffix}";
                break;

            case ContainerApp containerApp:
                containerApp.Name = $"{UniqueNamePrefix}-{containerApp.BicepIdentifier.ToLowerInvariant()}-{environmentSuffix}";
                break;

            case ContainerRegistryService containerRegistry:
                containerRegistry.Name = $"{UniqueNamePrefix}acr{environmentSuffix.ToLower()}";
                break;

            case OperationalInsightsWorkspace logAnalyticsWorkspace:
                logAnalyticsWorkspace.Name = $"{UniqueNamePrefix}-law-{environmentSuffix}";
                break;

            case ContainerAppManagedEnvironment containerAppEnvironment:
                containerAppEnvironment.Name = $"{UniqueNamePrefix}-cae-{environmentSuffix}";
                break;

            default:
                break;
        }
    }
}
