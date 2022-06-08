param privateDNSZoneName string
param vnetId string

resource aksHubLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDNSZoneName}/${privateDNSZoneName}-link-hub'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
