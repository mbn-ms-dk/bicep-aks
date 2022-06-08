param bastionIpId string
param subnetId string
param location string

resource bastion 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: 'bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconf'
        properties: {
          publicIPAddress: {
            id: bastionIpId
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}
