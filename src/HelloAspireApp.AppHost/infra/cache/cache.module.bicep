@description('The location for the resource(s) to be deployed.')
param location string = resourceGroup().location

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

resource cache 'Microsoft.Cache/redis@2024-11-01' = {
  name: 'sv-cache-${environmentSuffix}'
  location: location
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 1
    }
    enableNonSslPort: false
    disableAccessKeyAuthentication: true
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'aad-enabled': 'true'
    }
  }
  tags: {
    'aspire-resource-name': 'cache'
  }
}

output connectionString string = '${cache.properties.hostName},ssl=true'

output name string = cache.name
