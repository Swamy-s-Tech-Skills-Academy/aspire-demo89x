using Aspire.Hosting.Azure;
using HelloAspireApp.AppHost;
using Microsoft.Extensions.DependencyInjection;

var builder = DistributedApplication.CreateBuilder(args);

// Register the custom infrastructure resolver for fixed Azure resource names
builder.Services.Configure<AzureProvisioningOptions>(options =>
{
    options.ProvisioningBuildOptions.InfrastructureResolvers.Insert(0, new FixedNameInfrastructureResolver(builder.Configuration));
});

var cache = builder.AddAzureRedis("cache");

var apiService = builder.AddProject<Projects.HelloAspireApp_ApiService>("sv-api-service-dev");

builder.AddProject<Projects.HelloAspireApp_Web>("sv-web-frontend-dev")
    .WithExternalHttpEndpoints()
    .WithReference(cache)
    .WaitFor(cache)
    .WithReference(apiService)
    .WaitFor(apiService);


builder.Build().Run();
