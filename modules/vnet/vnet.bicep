param vnetAddressSpace object = {
  addressPrefixes: [
    '10.0.0.0/16'
  ]
}
param vnetNamePrefix string
param subnets array
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: '${vnetNamePrefix}-Vnet'
  location: location
  properties: {
    addressSpace: vnetAddressSpace
    subnets: subnets
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetSubnets array = vnet.properties.subnets
