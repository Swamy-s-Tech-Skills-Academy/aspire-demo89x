# Architecture Overview

This document provides a comprehensive overview of the aspire-demo89x project architecture, including system components, data flow, and integration patterns.

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                Azure Cloud                                          │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐│
│  │                        Azure Container Apps Environment                         ││
│  │                                                                                 ││
│  │  ┌─────────────────────┐        ┌─────────────────────┐                       ││
│  │  │    Web Frontend     │        │    API Service      │                       ││
│  │  │   (Blazor Server)   │───────▶│   (ASP.NET Core)    │                       ││
│  │  │                     │        │                     │                       ││
│  │  │  sv-web-frontend-   │        │  sv-api-service-    │                       ││
│  │  │  {env}-{region}     │        │  {env}-{region}     │                       ││
│  │  └─────────────────────┘        └─────────────────────┘                       ││
│  │                                                                                 ││
│  └─────────────────────────────────────────────────────────────────────────────────┘│
│                                            │                                        │
│                                            ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐│
│  │                         Azure Redis Cache                                      ││
│  │                      sv-cache-{env}-{region}                                   ││
│  └─────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐│
│  │                    Azure Log Analytics Workspace                               ││
│  │                      sv-law-{env}-{region}                                     ││
│  └─────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐│
│  │                    Azure Container Registry                                     ││
│  │                      svacr{env}{region}                                        ││
│  └─────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐│
│  │                    Azure Managed Identity                                       ││
│  │                      sv-mi-{env}-{region}                                      ││
│  └─────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. Application Layer

**Web Frontend (HelloAspireApp.Web)**

- **Technology**: Blazor Server
- **Purpose**: User interface and presentation layer
- **Features**:
  - Server-side rendering with SignalR
  - Real-time weather data display
  - Integration with API service
  - Redis caching for performance

**API Service (HelloAspireApp.ApiService)**

- **Technology**: ASP.NET Core Web API
- **Purpose**: Business logic and data processing
- **Features**:
  - RESTful API endpoints
  - Weather forecast service
  - Health checks
  - Structured logging

#### 2. Orchestration Layer

**App Host (HelloAspireApp.AppHost)**

- **Technology**: .NET Aspire
- **Purpose**: Service orchestration and configuration
- **Features**:
  - Service discovery and communication
  - Resource management
  - Custom infrastructure resolvers
  - Environment-specific configuration

#### 3. Infrastructure Layer

**Azure Container Apps Environment**

- **Purpose**: Container hosting platform
- **Features**:
  - Auto-scaling
  - Traffic management
  - Service mesh
  - Integrated monitoring

**Azure Redis Cache**

- **Purpose**: Distributed caching and session storage
- **Features**:
  - High-performance data store
  - Session persistence
  - Real-time data sharing

**Azure Log Analytics**

- **Purpose**: Centralized logging and monitoring
- **Features**:
  - Application insights
  - Performance monitoring
  - Log aggregation
  - Alert management

## 🔄 Data Flow

### Request Flow

1. **User Request** → Web Frontend (Blazor Server)
2. **API Call** → Web Frontend → API Service
3. **Data Processing** → API Service processes request
4. **Cache Check** → API Service checks Redis Cache
5. **Response** → API Service → Web Frontend → User

### Deployment Flow

1. **Code Commit** → GitHub Repository
2. **CI/CD Trigger** → GitHub Actions
3. **Build & Test** → Automated testing
4. **Container Build** → Docker image creation
5. **Registry Push** → Azure Container Registry
6. **Infrastructure Provision** → Bicep templates
7. **Application Deploy** → Azure Container Apps
8. **Health Check** → Service verification

## 🛠️ Technology Stack

### Development Stack

- **.NET 8.0** - Runtime platform
- **C#** - Primary programming language
- **Blazor Server** - Web UI framework
- **ASP.NET Core** - Web API framework
- **.NET Aspire** - Cloud-native orchestration

### Azure Services

- **Azure Container Apps** - Container hosting
- **Azure Container Registry** - Container images
- **Azure Redis Cache** - Distributed caching
- **Azure Log Analytics** - Monitoring & logging
- **Azure Managed Identity** - Authentication

### DevOps Tools

- **GitHub Actions** - CI/CD automation
- **Azure Developer CLI (azd)** - Infrastructure deployment
- **Bicep** - Infrastructure as Code
- **Docker** - Containerization

## 🔧 Configuration Management

### Environment Variables

The application uses environment-specific configuration:

```yaml
# Dev Environment
AZURE_ENV_NAME: aspire-dev-001
AZURE_LOCATION: eastus
AZURE_ENV_SUFFIX: D

# Test Environment
AZURE_ENV_NAME: aspire-test-001
AZURE_LOCATION: eastus
AZURE_ENV_SUFFIX: T
```

### Service Configuration

Services are configured through the AppHost:

```csharp
// Cache configuration
var cache = builder.AddAzureRedis("cache");

// API Service configuration
var apiService = builder.AddProject<Projects.HelloAspireApp_ApiService>("sv-api-service-dev");

// Web Frontend configuration
builder.AddProject<Projects.HelloAspireApp_Web>("sv-web-frontend-dev")
    .WithExternalHttpEndpoints()
    .WithReference(cache)
    .WithReference(apiService);
```

## 🔐 Security Architecture

### Authentication & Authorization

- **Azure Managed Identity**: Passwordless authentication
- **Federated Credentials**: GitHub Actions authentication
- **RBAC**: Role-based access control
- **Service-to-Service**: Managed identity for inter-service communication

### Security Boundaries

1. **Network Security**: Container Apps Environment isolation
2. **Identity Security**: Managed Identity for all services
3. **Data Security**: Redis with authentication
4. **Transport Security**: HTTPS/TLS encryption

## 📊 Monitoring & Observability

### Logging Strategy

- **Structured Logging**: JSON-formatted logs
- **Centralized Collection**: Azure Log Analytics
- **Application Insights**: Performance monitoring
- **Health Checks**: Service availability monitoring

### Metrics Collection

- **Application Metrics**: Custom application metrics
- **Infrastructure Metrics**: Azure Monitor integration
- **Performance Counters**: Resource utilization
- **Alert Rules**: Proactive monitoring

## 🚀 Scalability & Performance

### Auto-scaling

- **Container Apps**: CPU/Memory-based scaling
- **Redis Cache**: Clustered configuration
- **Load Balancing**: Built-in traffic distribution

### Performance Optimization

- **Caching Strategy**: Redis for frequently accessed data
- **Connection Pooling**: Efficient resource utilization
- **Async Processing**: Non-blocking operations
- **Image Optimization**: Multi-stage Docker builds

## 🔄 Deployment Patterns

### Blue-Green Deployment

- **Traffic Splitting**: Gradual rollout capabilities
- **Rollback Strategy**: Quick revert to previous version
- **Health Checks**: Automated deployment validation

### Multi-Environment Strategy

- **Dev Environment**: Continuous deployment
- **Test Environment**: Manual approval gates
- **Production**: Staged rollout with monitoring

---

_This architecture supports enterprise-grade applications with proper separation of concerns, scalability, and maintainability._
