param subnetId string
param location string

resource jumpboxnic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
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

output nicName string = jumpboxnic.name
output nicId string = jumpboxnic.id
