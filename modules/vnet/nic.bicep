param subnetId string
param location string

resource mbnnic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'mbnnic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

output nicName string = mbnnic.name
output nicId string = mbnnic.id
