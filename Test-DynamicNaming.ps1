# Test and Validation Script
# This script tests the complete end-to-end dynamic naming solution

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("D", "T", "S", "P")]
    [string]$EnvironmentSuffix,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDeploy,
    
    [Parameter(Mandatory = $false)]
    [switch]$CleanupOnly
)

# Test configuration
$script:TestResults = @()

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $result = @{
        TestName  = $TestName
        Passed    = $Passed
        Details   = $Details
        Timestamp = Get-Date
    }
    
    $script:TestResults += $result
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    Write-Host "$status - $TestName" -ForegroundColor $(if ($Passed) { "Green" } else { "Red" })
    if ($Details) {
        Write-Host "   Details: $Details" -ForegroundColor Gray
    }
}

function Test-BicepCompilation {
    Write-Host "`n🔧 Testing Bicep compilation..." -ForegroundColor Cyan
    
    try {
        # Test main.bicep compilation
        $result = az bicep build --file "infra/main.bicep" --stdout 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Main Bicep compilation" $true "Compiled successfully"
        }
        else {
            Write-TestResult "Main Bicep compilation" $false "Compilation failed: $result"
            return $false
        }
        
        # Test resources.bicep compilation
        $result = az bicep build --file "infra/resources.bicep" --stdout 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Resources Bicep compilation" $true "Compiled successfully"
        }
        else {
            Write-TestResult "Resources Bicep compilation" $false "Compilation failed: $result"
            return $false
        }
        
        # Test cache module compilation
        $result = az bicep build --file "infra/cache/cache.module.bicep" --stdout 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Cache module compilation" $true "Compiled successfully"
        }
        else {
            Write-TestResult "Cache module compilation" $false "Compilation failed: $result"
            return $false
        }
        
        return $true
    }
    catch {
        Write-TestResult "Bicep compilation setup" $false "Error: $_"
        return $false
    }
}

function Test-ParameterValidation {
    Write-Host "`n🧪 Testing parameter validation..." -ForegroundColor Cyan
    
    try {
        # Check main.parameters.json structure
        $paramsContent = Get-Content "infra/main.parameters.json" -Raw | ConvertFrom-Json
        
        # Verify environmentSuffix parameter exists
        if ($paramsContent.parameters.environmentSuffix) {
            Write-TestResult "EnvironmentSuffix parameter defined" $true "Found in main.parameters.json"
        }
        else {
            Write-TestResult "EnvironmentSuffix parameter defined" $false "Missing from main.parameters.json"
            return $false
        }
        
        # Verify environmentSuffix uses AZURE_ENV_SUFFIX variable
        $envSuffixValue = $paramsContent.parameters.environmentSuffix.value
        if ($envSuffixValue -eq '${AZURE_ENV_SUFFIX}') {
            Write-TestResult "EnvironmentSuffix uses AZURE_ENV_SUFFIX" $true "Correctly configured"
        }
        else {
            Write-TestResult "EnvironmentSuffix uses AZURE_ENV_SUFFIX" $false "Value: $envSuffixValue"
            return $false
        }
        
        return $true
    }
    catch {
        Write-TestResult "Parameter validation" $false "Error: $_"
        return $false
    }
}

function Test-ExpectedResourceNames {
    Write-Host "`n🎯 Testing expected resource names..." -ForegroundColor Cyan
    
    # Expected names based on environment suffix
    $expectedNames = @{
        ManagedIdentity   = "sv-mi-$EnvironmentSuffix"
        ContainerRegistry = "svacr$($EnvironmentSuffix.ToLower())"
        LogAnalytics      = "sv-law-$EnvironmentSuffix"
        ContainerAppsEnv  = "sv-cae-$EnvironmentSuffix"
        RedisCache        = "sv-cache-$EnvironmentSuffix"
        ResourceGroup     = "rg-aspire-test-001-$Location"
    }
    
    Write-TestResult "Expected naming pattern" $true "Environment suffix: $EnvironmentSuffix"
    foreach ($resource in $expectedNames.GetEnumerator()) {
        Write-Host "   $($resource.Key): $($resource.Value)" -ForegroundColor Gray
    }
    
    return $expectedNames
}

function Test-AzdEnvironmentSetup {
    Write-Host "`n🔧 Testing azd environment setup..." -ForegroundColor Cyan
    
    try {
        # Set the environment suffix
        $env:AZURE_ENV_SUFFIX = $EnvironmentSuffix
        azd env set AZURE_ENV_SUFFIX $EnvironmentSuffix
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "AZD environment variable set" $true "AZURE_ENV_SUFFIX = $EnvironmentSuffix"
        }
        else {
            Write-TestResult "AZD environment variable set" $false "Failed to set AZURE_ENV_SUFFIX"
            return $false
        }
        
        # Verify the variable is set
        $envValue = azd env get-values --output json | ConvertFrom-Json | Select-Object -ExpandProperty AZURE_ENV_SUFFIX -ErrorAction SilentlyContinue
        if ($envValue -eq $EnvironmentSuffix) {
            Write-TestResult "AZD environment variable verification" $true "Value confirmed: $envValue"
        }
        else {
            Write-TestResult "AZD environment variable verification" $false "Expected: $EnvironmentSuffix, Got: $envValue"
            return $false
        }
        
        return $true
    }
    catch {
        Write-TestResult "AZD environment setup" $false "Error: $_"
        return $false
    }
}

function Test-InfrastructureDeployment {
    param([hashtable]$ExpectedNames)
    
    Write-Host "`n🚀 Testing infrastructure deployment..." -ForegroundColor Cyan
    
    if ($SkipDeploy) {
        Write-TestResult "Infrastructure deployment" $true "Skipped by request"
        return $true
    }
    
    try {
        # Deploy infrastructure
        Write-Host "Deploying infrastructure with azd up..." -ForegroundColor Yellow
        $deployResult = azd up --confirm 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "AZD deployment" $true "Infrastructure deployed successfully"
        }
        else {
            Write-TestResult "AZD deployment" $false "Deployment failed: $deployResult"
            return $false
        }
        
        # Wait a moment for resources to be fully provisioned
        Start-Sleep -Seconds 30
        
        # Verify resource names in Azure
        $resourceGroup = $ExpectedNames.ResourceGroup
        
        # Check if resource group exists
        $rgExists = az group exists --name $resourceGroup
        if ($rgExists -eq "true") {
            Write-TestResult "Resource group created" $true "Found: $resourceGroup"
        }
        else {
            Write-TestResult "Resource group created" $false "Not found: $resourceGroup"
            return $false
        }
        
        # List resources in the resource group
        $resources = az resource list --resource-group $resourceGroup --output json | ConvertFrom-Json
        
        # Check managed identity
        $managedIdentity = $resources | Where-Object { $_.type -eq "Microsoft.ManagedIdentity/userAssignedIdentities" }
        if ($managedIdentity -and $managedIdentity.name -eq $ExpectedNames.ManagedIdentity) {
            Write-TestResult "Managed Identity naming" $true "Name: $($managedIdentity.name)"
        }
        else {
            Write-TestResult "Managed Identity naming" $false "Expected: $($ExpectedNames.ManagedIdentity), Found: $($managedIdentity.name)"
        }
        
        # Check container registry
        $acr = $resources | Where-Object { $_.type -eq "Microsoft.ContainerRegistry/registries" }
        if ($acr -and $acr.name -eq $ExpectedNames.ContainerRegistry) {
            Write-TestResult "Container Registry naming" $true "Name: $($acr.name)"
        }
        else {
            Write-TestResult "Container Registry naming" $false "Expected: $($ExpectedNames.ContainerRegistry), Found: $($acr.name)"
        }
        
        # Check Log Analytics workspace
        $logAnalytics = $resources | Where-Object { $_.type -eq "Microsoft.OperationalInsights/workspaces" }
        if ($logAnalytics -and $logAnalytics.name -eq $ExpectedNames.LogAnalytics) {
            Write-TestResult "Log Analytics naming" $true "Name: $($logAnalytics.name)"
        }
        else {
            Write-TestResult "Log Analytics naming" $false "Expected: $($ExpectedNames.LogAnalytics), Found: $($logAnalytics.name)"
        }
        
        # Check Container Apps Environment
        $cae = $resources | Where-Object { $_.type -eq "Microsoft.App/managedEnvironments" }
        if ($cae -and $cae.name -eq $ExpectedNames.ContainerAppsEnv) {
            Write-TestResult "Container Apps Environment naming" $true "Name: $($cae.name)"
        }
        else {
            Write-TestResult "Container Apps Environment naming" $false "Expected: $($ExpectedNames.ContainerAppsEnv), Found: $($cae.name)"
        }
        
        # Check Redis Cache
        $redis = $resources | Where-Object { $_.type -eq "Microsoft.Cache/redis" }
        if ($redis -and $redis.name -eq $ExpectedNames.RedisCache) {
            Write-TestResult "Redis Cache naming" $true "Name: $($redis.name)"
        }
        else {
            Write-TestResult "Redis Cache naming" $false "Expected: $($ExpectedNames.RedisCache), Found: $($redis.name)"
        }
        
        return $true
    }
    catch {
        Write-TestResult "Infrastructure deployment" $false "Error: $_"
        return $false
    }
}

function Test-ApplicationDeployment {
    Write-Host "`n📱 Testing application deployment..." -ForegroundColor Cyan
    
    if ($SkipDeploy) {
        Write-TestResult "Application deployment" $true "Skipped by request"
        return $true
    }
    
    try {
        # Get the application URL from azd
        $endpoints = azd show --output json | ConvertFrom-Json | Select-Object -ExpandProperty services
        
        foreach ($service in $endpoints.PSObject.Properties) {
            $serviceInfo = $service.Value
            if ($serviceInfo.project -and $serviceInfo.project.path -like "*Web*") {
                $appUrl = $serviceInfo.endpoint
                if ($appUrl) {
                    Write-TestResult "Web application endpoint" $true "URL: $appUrl"
                    
                    # Test if the application is responding
                    try {
                        $response = Invoke-WebRequest -Uri $appUrl -TimeoutSec 30 -UseBasicParsing
                        if ($response.StatusCode -eq 200) {
                            Write-TestResult "Web application health check" $true "HTTP 200 OK"
                        }
                        else {
                            Write-TestResult "Web application health check" $false "HTTP $($response.StatusCode)"
                        }
                    }
                    catch {
                        Write-TestResult "Web application health check" $false "Connection failed: $_"
                    }
                }
                else {
                    Write-TestResult "Web application endpoint" $false "No endpoint found"
                }
            }
        }
        
        return $true
    }
    catch {
        Write-TestResult "Application deployment test" $false "Error: $_"
        return $false
    }
}

function Invoke-Cleanup {
    Write-Host "`n🧹 Cleaning up test resources..." -ForegroundColor Cyan
    
    try {
        $result = azd down --force --purge 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Resource cleanup" $true "All resources removed"
        }
        else {
            Write-TestResult "Resource cleanup" $false "Cleanup failed: $result"
        }
    }
    catch {
        Write-TestResult "Resource cleanup" $false "Error: $_"
    }
}

function Show-TestSummary {
    Write-Host "`n📊 Test Summary" -ForegroundColor Cyan
    Write-Host "===============" -ForegroundColor Cyan
    
    $totalTests = $script:TestResults.Count
    $passedTests = ($script:TestResults | Where-Object { $_.Passed }).Count
    $failedTests = $totalTests - $passedTests
    
    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    Write-Host "Success Rate: $([Math]::Round(($passedTests / $totalTests) * 100, 1))%" -ForegroundColor Yellow
    
    if ($failedTests -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        $script:TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  ❌ $($_.TestName): $($_.Details)" -ForegroundColor Red
        }
    }
    
    Write-Host "`nTest completed at: $(Get-Date)" -ForegroundColor Gray
}

# Main execution
Write-Host "🚀 Starting End-to-End Dynamic Naming Test" -ForegroundColor Green
Write-Host "Environment Suffix: $EnvironmentSuffix" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "Skip Deploy: $SkipDeploy" -ForegroundColor Yellow
Write-Host "Cleanup Only: $CleanupOnly" -ForegroundColor Yellow

if ($CleanupOnly) {
    Invoke-Cleanup
    Show-TestSummary
    exit 0
}

# Run all tests
$bicepTest = Test-BicepCompilation
$paramTest = Test-ParameterValidation
$expectedNames = Test-ExpectedResourceNames
$azdTest = Test-AzdEnvironmentSetup

if ($bicepTest -and $paramTest -and $azdTest) {
    $deployTest = Test-InfrastructureDeployment -ExpectedNames $expectedNames
    if ($deployTest) {
        $appTest = Test-ApplicationDeployment
    }
}

Show-TestSummary

# Return appropriate exit code
$failedTests = ($script:TestResults | Where-Object { -not $_.Passed }).Count
exit $failedTests
