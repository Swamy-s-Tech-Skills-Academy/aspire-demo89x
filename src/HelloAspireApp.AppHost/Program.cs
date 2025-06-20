using Aspire.Hosting.Azure;
using HelloAspireApp.AppHost;
using Microsoft.Extensions.DependencyInjection;

var builder = DistributedApplication.CreateBuilder(args);

// Register the custom infrastructure resolver for fixed Azure resource names
builder.Services.Configure<AzureProvisioningOptions>(options =>
{
    options.ProvisioningBuildOptions.InfrastructureResolvers.Insert(0, new FixedNameInfrastructureResolver(builder.Configuration));
});

var cache = builder.AddRedis("cache");

var apiService = builder.AddProject<Projects.HelloAspireApp_ApiService>("api-service");

builder.AddProject<Projects.HelloAspireApp_Web>("web-frontend")
    .WithExternalHttpEndpoints()
    .WithReference(cache)
    .WaitFor(cache)
    .WithReference(apiService)
    .WaitFor(apiService);


builder.Build().Run();
