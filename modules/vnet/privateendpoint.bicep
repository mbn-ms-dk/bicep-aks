param privateEndpointName string
param subnetId object
param privateLinkServiceConnections array
param location string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: subnetId
    privateLinkServiceConnections: privateLinkServiceConnections
  }
}

output privateEndpointName string = privateEndpoint.name
