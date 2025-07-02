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

# Step 3: Apply custom naming to Bicep files
Write-Host "`n🔧 Applying custom resource names..." -ForegroundColor Cyan

$resourcesBicepPath = "infra/resources.bicep"
if (-not (Test-Path $resourcesBicepPath)) {
    Write-Error "❌ File not found: $resourcesBicepPath"
    exit 1
}

# Read and fix resources.bicep
$content = Get-Content $resourcesBicepPath -Raw
$replacements = @{
    # Managed Identity: mi-${resourceToken} -> sv-mi-P
    "name: 'mi-`\$\{resourceToken\}'"                      = "name: '$UniquePrefix-mi-$EnvironmentSuffix'"
    
    # Container Registry: replace('acr-${resourceToken}', '-', '') -> svacrs  
    "name: replace\('acr-`\$\{resourceToken\}', '-', ''\)" = "name: '$($UniquePrefix)acr$($EnvironmentSuffix.ToLower())'"
    
    # Log Analytics: law-${resourceToken} -> sv-law-P
    "name: 'law-`\$\{resourceToken\}'"                     = "name: '$UniquePrefix-law-$EnvironmentSuffix'"
    
    # Container Apps Environment: cae-${resourceToken} -> sv-cae-P
    "name: 'cae-`\$\{resourceToken\}'"                     = "name: '$UniquePrefix-cae-$EnvironmentSuffix'"
}

$modified = $false
foreach ($find in $replacements.Keys) {
    $replace = $replacements[$find]
    if ($content -match $find) {
        $content = $content -replace $find, $replace
        $modified = $true
        Write-Host "   ✅ Fixed: $($find.Replace('`\$\{resourceToken\}', '${resourceToken}'))" -ForegroundColor Green
    }
}

if ($modified) {
    $content | Set-Content $resourcesBicepPath -NoNewline
    Write-Host "🎉 Resource names fixed successfully!" -ForegroundColor Green
}
else {
    Write-Host "ℹ️  No changes needed - resource names already correct" -ForegroundColor Blue
}

# Step 4: Summary
Write-Host "`n📋 Final Resource Names:" -ForegroundColor Cyan
Write-Host "   Managed Identity: $UniquePrefix-mi-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Container Registry: $($UniquePrefix)acr$($EnvironmentSuffix.ToLower())" -ForegroundColor White
Write-Host "   Log Analytics: $UniquePrefix-law-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Container Apps Env: $UniquePrefix-cae-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Redis Cache: $UniquePrefix-cache-$EnvironmentSuffix (via FixedNameInfrastructureResolver)" -ForegroundColor Green

# Step 5: Ready for deployment
Write-Host "`n🎯 Ready for deployment! Run:" -ForegroundColor Cyan
Write-Host "   azd up" -ForegroundColor Yellow

Write-Host "`n✨ All resource names are now consistent with your naming convention!" -ForegroundColor Green
