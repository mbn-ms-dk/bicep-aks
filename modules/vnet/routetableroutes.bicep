param routeTableName string
param routeName string
param properties object

resource rtRoutes 'Microsoft.Network/routeTables/routes@2021-08-01' = {
  name: '${routeTableName}/${routeName}'
  properties: properties
}
