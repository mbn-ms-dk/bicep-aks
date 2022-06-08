param publicIpName string
param publicIpSku object
param publicIpProperties object
param location string

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: publicIpName
  location: location
  sku: publicIpSku
  properties: publicIpProperties
}

output publicIpId string = publicIp.id
