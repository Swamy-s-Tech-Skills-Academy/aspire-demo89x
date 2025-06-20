# .NET Aspire With AI Stack

A distributed AI-powered architecture built with .NET Aspire, PostgreSQL, Redis, RabbitMQ, Keycloak, Ollama, and VectorDB.

## Deployment

```powershell
D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> az account show

D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> azd init

# This will create a new Azure Developer CLI project in the current directory.
D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> dotnet run --project .\HelloAspireApp.AppHost.csproj --publisher manifest --output-path ./aspire-manifest.json

D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> azd config set alpha.infraSynth on
D:\STSA\aspire-demo89x\src\HelloAspireApp.AppHost> azd infra synth

azd auth login --scope https://management.azure.com//.default

azd config set alpha.resourceGroupDeployments on

azd up
```
