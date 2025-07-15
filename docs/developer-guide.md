# Developer Guide

This guide provides developers with comprehensive information for working with the aspire-demo89x project, including setup, development workflows, and best practices.

## 🚀 Getting Started

### Prerequisites

**Required Software:**

- .NET 8.0 SDK or later
- Visual Studio 2022 17.8+ or VS Code with C# extension
- Docker Desktop
- Azure Developer CLI (azd)
- Git

**Optional but Recommended:**

- Azure CLI
- PowerShell 7+
- Windows Terminal
- GitHub CLI

### Environment Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Swamy-s-Tech-Skills-Academy/aspire-demo89x.git
   cd aspire-demo89x
   ```

2. **Install .NET Aspire Workload**

   ```bash
   dotnet workload install aspire
   ```

3. **Verify Installation**
   ```bash
   dotnet workload list
   # Should show "aspire" as installed
   ```

## 🏗️ Project Structure

### Solution Overview

```
aspire-demo89x/
├── src/
│   ├── HelloAspireApp.ApiService/     # Web API service
│   ├── HelloAspireApp.AppHost/        # Aspire orchestrator
│   ├── HelloAspireApp.ServiceDefaults/ # Common service configurations
│   └── HelloAspireApp.Web/            # Blazor Server web app
├── docs/                              # Documentation
├── .github/workflows/                 # CI/CD pipelines
├── aspire-demo89x.sln                # Solution file
└── README.md                         # Project overview
```

### Key Components

**AppHost Project**

- Orchestrates all services and dependencies
- Configures service discovery and communication
- Manages Azure resource bindings
- Contains infrastructure-as-code (Bicep templates)

**API Service**

- ASP.NET Core Web API
- Provides weather forecast endpoints
- Implements health checks
- Uses structured logging

**Web Frontend**

- Blazor Server application
- Consumes API service
- Implements caching with Redis
- Real-time UI updates

**Service Defaults**

- Common configurations for all services
- Shared middleware and extensions
- Standard health checks and logging

## 🔧 Development Workflow

### Local Development

1. **Start the Solution**

   ```bash
   cd src/HelloAspireApp.AppHost
   dotnet run
   ```

2. **Access Applications**

   - **Aspire Dashboard**: `https://localhost:15888`
   - **Web Frontend**: `https://localhost:7236`
   - **API Service**: `https://localhost:7239`

3. **View Logs and Metrics**
   - Open Aspire Dashboard
   - Navigate to different services
   - View logs, metrics, and traces

### Development with Azure Resources

1. **Setup Azure Resources**

   ```bash
   cd src/HelloAspireApp.AppHost
   azd auth login
   azd env new aspire-dev-local
   azd env set AZURE_LOCATION eastus
   azd env set AZURE_ENV_SUFFIX D
   azd provision
   ```

2. **Connect to Azure Resources**
   ```bash
   # The AppHost will automatically connect to provisioned Azure resources
   dotnet run
   ```

### Hot Reload and Development

- **Code Changes**: Automatic hot reload for most changes
- **Configuration Changes**: Restart required for appsettings.json changes
- **Infrastructure Changes**: Re-run `azd provision` for infrastructure updates

## 🧪 Testing

### Unit Testing

```bash
# Run all tests
dotnet test

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"

# Run specific test project
dotnet test src/HelloAspireApp.ApiService.Tests/
```

### Integration Testing

```bash
# Start test environment
cd src/HelloAspireApp.AppHost
dotnet run --environment Testing

# Run integration tests
dotnet test --filter Category=Integration
```

### Local Testing with Azure Resources

1. **Deploy to Test Environment**

   ```bash
   azd env new aspire-test-local
   azd env set AZURE_ENV_SUFFIX T
   azd up
   ```

2. **Test Against Azure Resources**
   ```bash
   # Run tests against deployed resources
   dotnet test --filter Category=Azure
   ```

## 🛠️ Key Development Patterns

### Service Communication

Services communicate through .NET Aspire's service discovery:

```csharp
// In Web project
public class WeatherApiClient
{
    private readonly HttpClient _httpClient;

    public WeatherApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<WeatherForecast[]> GetWeatherAsync()
    {
        // Service discovery automatically resolves "sv-api-service-dev"
        return await _httpClient.GetFromJsonAsync<WeatherForecast[]>("/weatherforecast");
    }
}
```

### Configuration Management

```csharp
// appsettings.json
{
  "ConnectionStrings": {
    "cache": "your-redis-connection-string"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}

// Usage in code
public class MyService
{
    private readonly IConfiguration _configuration;

    public MyService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public void DoSomething()
    {
        var connectionString = _configuration.GetConnectionString("cache");
        // Use connection string
    }
}
```

### Caching Implementation

```csharp
// Register Redis cache
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("cache");
});

// Use in service
public class WeatherService
{
    private readonly IDistributedCache _cache;

    public WeatherService(IDistributedCache cache)
    {
        _cache = cache;
    }

    public async Task<WeatherForecast[]> GetWeatherAsync()
    {
        var cachedWeather = await _cache.GetStringAsync("weather");
        if (cachedWeather != null)
        {
            return JsonSerializer.Deserialize<WeatherForecast[]>(cachedWeather);
        }

        // Fetch and cache data
        var weather = await FetchWeatherAsync();
        await _cache.SetStringAsync("weather", JsonSerializer.Serialize(weather),
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
            });

        return weather;
    }
}
```

### Health Checks

```csharp
// In Program.cs
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy())
    .AddRedis(builder.Configuration.GetConnectionString("cache"));

// Custom health check
public class CustomHealthCheck : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        // Implement health check logic
        return Task.FromResult(HealthCheckResult.Healthy());
    }
}
```

## 🔐 Security Best Practices

### Authentication and Authorization

```csharp
// Configure authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // JWT configuration
    });

// Use in controllers
[Authorize]
[ApiController]
public class WeatherForecastController : ControllerBase
{
    [HttpGet]
    public async Task<WeatherForecast[]> Get()
    {
        // Authorized endpoint
        return await GetWeatherAsync();
    }
}
```

### Secrets Management

```csharp
// Use Azure Key Vault or User Secrets
// For development
dotnet user-secrets set "ConnectionStrings:Database" "your-connection-string"

// For production, use Azure Key Vault
builder.Configuration.AddAzureKeyVault(
    new Uri("https://your-keyvault.vault.azure.net/"),
    new DefaultAzureCredential());
```

### Input Validation

```csharp
// Use data annotations
public class WeatherRequest
{
    [Required]
    [StringLength(100)]
    public string City { get; set; }

    [Range(1, 30)]
    public int Days { get; set; }
}

// Validate in controllers
[HttpPost]
public async Task<IActionResult> CreateWeather([FromBody] WeatherRequest request)
{
    if (!ModelState.IsValid)
    {
        return BadRequest(ModelState);
    }

    // Process valid request
    return Ok();
}
```

## 📊 Monitoring and Logging

### Structured Logging

```csharp
// Configure logging
builder.Logging.AddConsole();
builder.Logging.AddApplicationInsights();

// Use in services
public class WeatherService
{
    private readonly ILogger<WeatherService> _logger;

    public WeatherService(ILogger<WeatherService> logger)
    {
        _logger = logger;
    }

    public async Task<WeatherForecast[]> GetWeatherAsync()
    {
        _logger.LogInformation("Fetching weather data");

        try
        {
            var weather = await FetchWeatherAsync();
            _logger.LogInformation("Successfully fetched {Count} weather records", weather.Length);
            return weather;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching weather data");
            throw;
        }
    }
}
```

### Application Insights

```csharp
// Configure Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Custom telemetry
public class TelemetryService
{
    private readonly TelemetryClient _telemetryClient;

    public TelemetryService(TelemetryClient telemetryClient)
    {
        _telemetryClient = telemetryClient;
    }

    public void TrackEvent(string eventName, Dictionary<string, string> properties = null)
    {
        _telemetryClient.TrackEvent(eventName, properties);
    }
}
```

## 🧩 Extending the Application

### Adding New Services

1. **Create New Project**

   ```bash
   dotnet new webapi -n HelloAspireApp.NewService
   dotnet sln add src/HelloAspireApp.NewService
   ```

2. **Add to AppHost**

   ```csharp
   var newService = builder.AddProject<Projects.HelloAspireApp_NewService>("new-service");

   // Reference from other services
   builder.AddProject<Projects.HelloAspireApp_Web>("web")
       .WithReference(newService);
   ```

3. **Configure in Infrastructure**
   ```bicep
   // Add to resources.bicep if needed
   resource newServiceStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
     name: 'sv-storage-${environmentSuffix}-${regionAbbreviation}'
     location: location
     // Configuration
   }
   ```

### Adding New Azure Resources

1. **Create Bicep Module**

   ```bicep
   // infra/storage/storage.module.bicep
   @description('Environment suffix for resource naming')
   param environmentSuffix string

   @description('Region abbreviation')
   param regionAbbreviation string

   resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
     name: 'sv-storage-${environmentSuffix}-${regionAbbreviation}'
     location: location
     sku: {
       name: 'Standard_LRS'
     }
   }

   output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
   ```

2. **Add to Main Template**

   ```bicep
   // infra/main.bicep
   module storage 'storage/storage.module.bicep' = {
     name: 'storage'
     scope: rg
     params: {
       environmentSuffix: environmentSuffix
       regionAbbreviation: regionAbbreviation
     }
   }
   ```

3. **Use in Application**

   ```csharp
   // In AppHost
   var storage = builder.AddAzureStorage("storage");

   // In service
   builder.AddProject<Projects.HelloAspireApp_Service>("service")
       .WithReference(storage);
   ```

## 🔄 CI/CD Integration

### GitHub Actions Workflow

The project includes automated CI/CD workflows:

- **Build and Test**: Runs on pull requests
- **Deploy to Dev**: Automatic deployment to development environment
- **Deploy to Test**: Manual approval required

### Custom Deployment Scripts

```bash
# Custom deployment script
#!/bin/bash
ENVIRONMENT=$1
REGION=$2

echo "Deploying to $ENVIRONMENT in $REGION"

# Set environment variables
export AZURE_ENV_NAME="aspire-$ENVIRONMENT-001"
export AZURE_LOCATION=$REGION
export AZURE_ENV_SUFFIX=${ENVIRONMENT:0:1}

# Deploy
azd up --no-prompt
```

## 🐛 Troubleshooting

### Common Development Issues

**Issue: Aspire Dashboard not accessible**

```bash
# Check if ports are available
netstat -an | findstr :15888

# Try different port
dotnet run --dashboard-port 15889
```

**Issue: Service discovery not working**

```bash
# Verify service registration in AppHost
var apiService = builder.AddProject<Projects.HelloAspireApp_ApiService>("api");

// Check service name in client
public class WeatherApiClient
{
    public WeatherApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri("https://api/"); // Must match service name
    }
}
```

**Issue: Redis connection failures**

```bash
# Check Redis connection string
azd env get-values | grep -i redis

# Test Redis connectivity
redis-cli -h your-redis-host -p 6380 -a your-password ping
```

### Performance Optimization

**Database Connections**

```csharp
// Use connection pooling
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString, sqlOptions =>
        sqlOptions.EnableRetryOnFailure()));
```

**Caching Strategy**

```csharp
// Implement proper caching
public class CachedWeatherService
{
    private readonly IMemoryCache _memoryCache;
    private readonly IDistributedCache _distributedCache;

    public async Task<WeatherForecast[]> GetWeatherAsync()
    {
        // Try memory cache first
        if (_memoryCache.TryGetValue("weather", out WeatherForecast[] cached))
        {
            return cached;
        }

        // Then distributed cache
        var distributedCached = await _distributedCache.GetStringAsync("weather");
        if (distributedCached != null)
        {
            var weather = JsonSerializer.Deserialize<WeatherForecast[]>(distributedCached);
            _memoryCache.Set("weather", weather, TimeSpan.FromMinutes(1));
            return weather;
        }

        // Finally fetch from source
        var freshWeather = await FetchWeatherAsync();
        await _distributedCache.SetStringAsync("weather", JsonSerializer.Serialize(freshWeather));
        _memoryCache.Set("weather", freshWeather, TimeSpan.FromMinutes(1));

        return freshWeather;
    }
}
```

## 📚 Learning Resources

### .NET Aspire Resources

- [Official .NET Aspire Documentation](https://learn.microsoft.com/en-us/dotnet/aspire/)
- [.NET Aspire Samples](https://github.com/dotnet/aspire-samples)
- [Building Cloud-Native apps with .NET Aspire](https://learn.microsoft.com/en-us/training/paths/dotnet-aspire/)

### Azure Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)

### Development Tools

- [Visual Studio Code Extensions](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit)
- [Azure Tools for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)
- [Docker Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)

## 🤝 Contributing

### Development Process

1. **Fork the repository**
2. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
4. **Write tests**
5. **Run tests and ensure they pass**

   ```bash
   dotnet test
   ```

6. **Submit a pull request**

### Code Style

- Follow Microsoft's C# coding conventions
- Use consistent naming patterns
- Include XML documentation for public APIs
- Write meaningful commit messages

### Testing Guidelines

- Write unit tests for all business logic
- Include integration tests for API endpoints
- Test error handling and edge cases
- Maintain good test coverage

---

_This developer guide provides the foundation for productive development on the aspire-demo89x project. Keep it updated as the project evolves._
