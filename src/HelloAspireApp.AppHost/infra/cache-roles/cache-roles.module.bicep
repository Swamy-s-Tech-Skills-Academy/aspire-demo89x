param principalId string

param principalName string

@description('Environment suffix for resource naming (D/T/S/P)')
param environmentSuffix string

@description('Region abbreviation for resource naming (use/usc/etc)')
param regionAbbreviation string

resource cache 'Microsoft.Cache/redis@2024-11-01' existing = {
  name: 'sv-cache-${environmentSuffix}-${regionAbbreviation}'
}

resource cache_contributor 'Microsoft.Cache/redis/accessPolicyAssignments@2024-11-01' = {
  name: guid(cache.id, principalId, 'Data Contributor')
  properties: {
    accessPolicyName: 'Data Contributor'
    objectId: principalId
    objectIdAlias: principalName
  }
  parent: cache
}
