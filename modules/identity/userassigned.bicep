param baseName string
param location string

resource azIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${baseName}identity'
  location: location
}

output identityId string = azIdentity.id
output clientId string = azIdentity.properties.clientId
output principalid string = azIdentity.properties.principalId
