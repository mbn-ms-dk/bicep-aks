param principalid string
param roleGuid string

resource role_assignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(subscription().id, principalid)
  properties: {
    principalId: principalid
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
  }
}
