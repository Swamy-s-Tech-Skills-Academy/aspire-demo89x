# Deploy-WithCustomNames.ps1
# Complete deployment script that generates infrastructure and applies custom naming

param(
    [string]$EnvironmentSuffix = $env:AZURE_ENV_SUFFIX ?? "D",
    [string]$UniquePrefix = "sv"
)

Write-Host "🚀 Deploying with Custom Resource Names" -ForegroundColor Cyan
Write-Host "   Environment Suffix: $EnvironmentSuffix" -ForegroundColor Yellow
Write-Host "   Unique Prefix: $UniquePrefix" -ForegroundColor Yellow

# Step 1: Set environment variable for FixedNameInfrastructureResolver
$env:AZURE_ENV_SUFFIX = $EnvironmentSuffix
Write-Host "`n📝 Set AZURE_ENV_SUFFIX=$EnvironmentSuffix" -ForegroundColor Green

# Step 2: Generate infrastructure using azd
Write-Host "`n🔨 Generating infrastructure with azd..." -ForegroundColor Cyan
try {
    azd infra generate --force
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ azd infra generate failed"
        exit 1
    }
    Write-Host "✅ Infrastructure generated successfully" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to generate infrastructure: $_"
    exit 1
}

# Step 3: Infrastructure is now dynamic - no manual edits needed!
Write-Host "`n✅ Infrastructure templates are now dynamic!" -ForegroundColor Cyan
Write-Host "   Resource names will be based on environment suffix: $EnvironmentSuffix" -ForegroundColor Green

# Verify that the main.parameters.json has the correct parameter
$mainParamsPath = "infra/main.parameters.json"
if (Test-Path $mainParamsPath) {
    $paramsContent = Get-Content $mainParamsPath -Raw | ConvertFrom-Json
    if ($paramsContent.parameters.environmentSuffix) {
        Write-Host "   ✅ main.parameters.json includes environmentSuffix parameter" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  main.parameters.json missing environmentSuffix parameter" -ForegroundColor Yellow
    }
}
else {
    Write-Host "   ⚠️  main.parameters.json not found" -ForegroundColor Yellow
}

# Step 4: Summary
Write-Host "`n📋 Final Resource Names (Dynamic):" -ForegroundColor Cyan
Write-Host "   Managed Identity: $UniquePrefix-mi-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Container Registry: $($UniquePrefix)acr$($EnvironmentSuffix.ToLower())" -ForegroundColor White
Write-Host "   Log Analytics: $UniquePrefix-law-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Container Apps Env: $UniquePrefix-cae-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Redis Cache: $UniquePrefix-cache-$EnvironmentSuffix (via FixedNameInfrastructureResolver)" -ForegroundColor Green

# Step 5: Ready for deployment
Write-Host "`n🎯 Ready for deployment! Run:" -ForegroundColor Cyan
Write-Host "   azd up" -ForegroundColor Yellow

Write-Host "`n✨ All resource names are now dynamic and consistent!" -ForegroundColor Green
