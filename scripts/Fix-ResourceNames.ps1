# Fix-ResourceNames.ps# Define replacements
$replacements = @{
    # Managed Identity: mi-${resourceToken} -> sv-mi-P
    "name: 'mi-`${resourceToken}'"                       = "name: '$UniquePrefix-mi-$EnvironmentSuffix'"
    
    # Container Registry: replace('acr-${resourceToken}', '-', '') -> svacrp
    "name: replace\('acr-`\${resourceToken}', '-', ''\)" = "name: '$UniquePrefix' + 'acr' + toLower('$EnvironmentSuffix')"
    
    # Log Analytics: law-${resourceToken} -> sv-law-P
    "name: 'law-`${resourceToken}'"                      = "name: '$UniquePrefix-law-$EnvironmentSuffix'"
    
    # Container Apps Environment: cae-${resourceToken} -> sv-cae-P
    "name: 'cae-`${resourceToken}'"                      = "name: '$UniquePrefix-cae-$EnvironmentSuffix'"
}ess generated Bicep files to use custom naming convention

param(
    [string]$EnvironmentSuffix = $env:AZURE_ENV_SUFFIX ?? "D",
    [string]$UniquePrefix = "sv"
)

$resourcesBicepPath = "src/HelloAspireApp.AppHost/infra/resources.bicep"

Write-Host "🔧 Fixing resource names in $resourcesBicepPath..." -ForegroundColor Cyan
Write-Host "   Environment Suffix: $EnvironmentSuffix" -ForegroundColor Yellow
Write-Host "   Unique Prefix: $UniquePrefix" -ForegroundColor Yellow

if (-not (Test-Path $resourcesBicepPath)) {
    Write-Error "❌ File not found: $resourcesBicepPath"
    exit 1
}

# Read the current content
$content = Get-Content $resourcesBicepPath -Raw

# Define replacements
$replacements = @{
    # Managed Identity: mi-${resourceToken} -> sv-mi-P
    "name: 'mi-`${resourceToken}'"                      = "name: '$UniquePrefix-mi-$EnvironmentSuffix'"
    
    # Container Registry: replace('acr-${resourceToken}', '-', '') -> svacrp
    "name: replace\('acr-`${resourceToken}', '-', ''\)" = "name: '$UniquePrefix' + 'acr' + toLower('$EnvironmentSuffix')"
    
    # Log Analytics: law-${resourceToken} -> sv-law-P
    "name: 'law-`${resourceToken}'"                     = "name: '$UniquePrefix-law-$EnvironmentSuffix'"
    
    # Container Apps Environment: cae-${resourceToken} -> sv-cae-P
    "name: 'cae-`${resourceToken}'"                     = "name: '$UniquePrefix-cae-$EnvironmentSuffix'"
}

# Apply replacements
$modified = $false
foreach ($find in $replacements.Keys) {
    $replace = $replacements[$find]
    if ($content -match [regex]::Escape($find)) {
        $content = $content -replace [regex]::Escape($find), $replace
        $modified = $true
        Write-Host "   ✅ Fixed: $find" -ForegroundColor Green
    }
}

if ($modified) {
    # Write back to file
    $content | Set-Content $resourcesBicepPath -NoNewline
    Write-Host "🎉 Resource names fixed successfully!" -ForegroundColor Green
}
else {
    Write-Host "ℹ️  No changes needed - resource names already correct" -ForegroundColor Blue
}

# Summary of expected resource names
Write-Host "`n📋 Expected Resource Names:" -ForegroundColor Cyan
Write-Host "   Managed Identity: $UniquePrefix-mi-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Container Registry: $($UniquePrefix)acr$($EnvironmentSuffix.ToLower())" -ForegroundColor White
Write-Host "   Log Analytics: $UniquePrefix-law-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Container Apps Env: $UniquePrefix-cae-$EnvironmentSuffix" -ForegroundColor White
Write-Host "   Redis Cache: $UniquePrefix-cache-$EnvironmentSuffix (via FixedNameInfrastructureResolver)" -ForegroundColor Green
