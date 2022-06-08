param rtName string
param location string

resource rt 'Microsoft.Network/routeTables@2021-08-01' = {
  name: rtName
  location: location
}

output routeTableId string = rt.id
