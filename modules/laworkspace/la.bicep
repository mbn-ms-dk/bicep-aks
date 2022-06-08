param baseName string
param location string

resource la 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${baseName}-workspace'
  location: location
}

output laWsId string = la.id
