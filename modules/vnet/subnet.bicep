param vnetName string
param subnetName string
param props object

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  name: '${vnetName}/${subnetName}'
  properties: props
}

output subnetId string = subnet.id
