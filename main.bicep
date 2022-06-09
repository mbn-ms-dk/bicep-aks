targetScope = 'subscription'

//parameters
param baseName string
param location string 
param pubkeydata string
param script64 string
param aadids string


param hubVNETaddPrefixes array = [
  '10.0.0.0/16'
]
param hubVNETdefaultSubnet object = {
  properties: {
    addressPrefix: '10.0.0.0/24'
  }
  name: 'default'
}
param hubVNETfirewallSubnet object = {
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
  name: 'AzureFirewallSubnet'
}
param hubVNETVMSubnet object = {
  properties: {
    addressPrefix: '10.0.2.0/28'
  }
  name: 'vmsubnet'
}
param hubVNETBastionSubnet object = {
  properties: {
    addressPrefix: '10.0.3.0/27'
  }
  name: 'AzureBastionSubnet'
}
param spokeVNETaddPrefixes array = [
  '10.1.0.0/16'
]
param spokeVNETdefaultSubnet object = {
  properties: {
    addressPrefix: '10.1.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
  name: 'default'
}

//variables
var rgName = 'rg-${baseName}'
//acr needs a unique name
var acrName = 'acr${uniqueString(rgName)}'
//aad groups
var aadGroupdIds = array(aadids)

//modules
//RG
module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

//VnetHub
module vnetHub 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'hub-Vnet'
  params: {
    location: location
    vnetAddressSpace: {
      addressPrefixes: hubVNETaddPrefixes
    }
    vnetNamePrefix: 'hub'
    subnets: [
      hubVNETdefaultSubnet
      hubVNETfirewallSubnet
      hubVNETVMSubnet
      hubVNETBastionSubnet
    ]
  }
  dependsOn: [
    rg
  ]
}

//VnetSpoke
module vnetSpoke 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'spoke-Vnet'
  params: {
    location: location
    vnetAddressSpace: {
      addressPrefixes: spokeVNETaddPrefixes
    }
    vnetNamePrefix: 'spoke'
    subnets: [
      spokeVNETdefaultSubnet 
      {
        properties: {
          addressPrefix: '10.1.2.0/23'
          privateEndpointNetworkPolicies: 'Disabled'
          routeTable: {
            id: routetable.outputs.routeTableId
          }          
        }
        name: 'AKS'
      }
    ]
  }
  dependsOn: [
    rg
  ]
}

//peering hub
module vnetPeeringHub 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vnetpeeringhub'
  params: {
    peeringName: 'Hub-to-Spoke'
    vnetName: vnetHub.outputs.vnetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: vnetSpoke.outputs.vnetId
      }
    }
  }
}

//peering spoke
module vnetpeeringspoke 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vnetpeeringspoke'
  params: {
    peeringName: 'Spoke-to-Hub'
    vnetName: vnetSpoke.outputs.vnetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: vnetHub.outputs.vnetId
      }
    }    
  }
}

//PIP FW
module publicipFw 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'publicipFw'
  params: {
    publicIpName: 'pip-fw'
    location: location
    publicIpProperties: {
      publicIPAllocationMethod: 'static'
    }
    publicIpSku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

//resource subnetfw
resource subnetfw 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetHub.outputs.vnetName}/AzureFirewallSubnet'
}

//azure firewall
module azfirewall 'modules/vnet/firewall.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'azfirewall'
  params: {
    fwname: 'azfirewall'
    location: location    
    fwipConfigurations: [
      {
        name: 'fwPublicIP'
        properties: {
          subnet: {
            id: subnetfw.id
          }
          publicIPAddress: {
            id: publicipFw.outputs.publicIpId
          }
        }
      }
    ]
    fwapplicationRuleCollections: [
      {
        name: 'Helper-tools'
        properties: {
          priority: 101
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Allow-ifconfig'
              protocols: [
                {
                  port: 80
                  protocolType: 'Http'
                }
                {
                  port: 443
                  protocolType: 'Https'
                }                
              ]
              targetFqdns: [
                'ifconfig.co' 
                'api.snapcraft.io' 
                'jsonip.com' 
                'kubernaut.io' 
                'motd.ubuntu.com'
              ]
              sourceAddresses: [
                '10.0.0.0/16'
                '10.1.0.0/16'
              ]
            }
          ]
        }
      }      
      {
        name: 'AKS-egress-application'
        properties: {
          priority: 102
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Egress'
              protocols: [
                {
                  port: 443
                  protocolType: 'Https'
                }                
              ]
              targetFqdns: [
                '*.azmk8s.io' 
                'aksrepos.azurecr.io'
                //'*.blob.core.windows.net' 
                'mcr.microsoft.com' 
                '*.cdn.mscr.io' 
                //'management.azure.com' 
                //'login.microsoftonline.com' 
                'packages.azure.com' 
                'acs-mirror.azureedge.net' 
                '*.opinsights.azure.com' 
                '*.monitoring.azure.com' 
                'dc.services.visualstudio.com'
              ]
              sourceAddresses: [
                '10.0.0.0/16'
                '10.1.0.0/16'
              ]
            }
            {
              name: 'Registries'
              protocols: [
                {
                  port: 443
                  protocolType: 'Https'
                }                
              ]
              targetFqdns: [
                '*.data.mcr.microsoft.com' 
                '*.azurecr.io' 
                '*.gcr.io' 
                'gcr.io' 
                'storage.googleapis.com' 
                '*.docker.io' 
                'quay.io' 
                '*.quay.io' 
                '*.cloudfront.net' 
                'production.cloudflare.docker.com'
              ]
              sourceAddresses: [
                '10.0.0.0/16'
                '10.1.0.0/16'
              ]
            }
            {
              name: 'Additional-Usefull-Address'
              protocols: [
                {
                  port: 443
                  protocolType: 'Https'
                }                
              ]
              targetFqdns: [
                'grafana.net' 
                'grafana.com' 
                'stats.grafana.org' 
                'github.com' 
                'raw.githubusercontent.com' 
                'security.ubuntu.com' 
                'security.ubuntu.com' 
                'packages.microsoft.com' 
                'azure.archive.ubuntu.com' 
                'security.ubuntu.com' 
                //'hack32003.vault.azure.net' 
                '*.letsencrypt.org' 
                'usage.projectcalico.org' 
                
                'vortex.data.microsoft.com'
              ]
              sourceAddresses: [
                '10.0.0.0/16'
                '10.1.0.0/16'
              ]
            }  
            {
              name: 'AKS-FQDN-TAG'
              protocols: [
                {
                  port: 80
                  protocolType: 'Http'
                }                
                {
                  port: 443
                  protocolType: 'Https'
                }                
              ]
              targetFqdns: []
              fqdnTags: [
                'AzureKubernetesService'
              ]
              sourceAddresses: [
                '10.0.0.0/16'
                '10.1.0.0/16'
              ]
            }                                   
          ]
        }
      }            
    ]
    fwnatRuleCollections: []
    fwnetworkRuleCollections: [
      {
        name: 'AKS-egress'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'NTP'
              protocols: [
                'UDP'
              ]
              sourceAddresses: [
                '10.0.0.0/16'
                '10.1.0.0/16'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '123'
              ]
            }
          ]
        }
      }      
    ]
  } 
}

//routetable
module routetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aks-udr'
  params: {
    rtName: 'aks-udr'
    location: location
  } 
}

//routetable routes
module routetableRoutes 'modules/vnet/routetableroutes.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aks-udr-route'
  params: {
    routeTableName: 'aks-udr'
    routeName: 'aks-udr-route'
    properties: {
      nextHopType: 'virtualAppliance'
      nextHopIpAddress: azfirewall.outputs.fwPrivateIP
      addressPrefix: '0.0.0.0/0'
    }
  }
}

//acr
module acrDeploy 'modules/acr/acr.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'acrDeploy'
  params: {
    acrName: acrName
    location: location
  }
}

//subnet acrprivate
resource subnetacrpvt 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetSpoke.outputs.vnetName}/default' 
}

//acr private endpoint
module acrpvtEndpoint 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'acrPvtEndpoint'
  params:{
    privateEndpointName: 'actPvtEndpoint'
    location: location
    privateLinkServiceConnections: [
      {
        name: 'acrPvtEndpointConnection'
        properties: {
          privateLinkServiceId: acrDeploy.outputs.acrId
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    subnetId: {
      id: subnetacrpvt.id
    }
  }
}

//private dns acr zone
module privateDNSACRZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSACRZone'
  params:{
    privateDNSZoneName: 'privatelink.azurecr.io'
  }
}

//private dns
module privateDNS 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNS'
  params: {
    privateDNSZoneName: privateDNSACRZone.outputs.privateDNSZoneName
    privateEndpointName: acrpvtEndpoint.outputs.privateEndpointName
    virtualNetworkId: vnetSpoke.outputs.vnetId
    privateDNSZoneId: privateDNSACRZone.outputs.privateDNSZoneId
  }
}

//log analytics aks workspace
module akslaws 'modules/laworkspace/la.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aks-la-ws'
  params:{
    baseName: baseName
    location: location
  }
}

//aks subnet
resource subnetaks 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetSpoke.outputs.vnetName}/AKS'
}

//private aks DNS Zone
module privateDNSAKSZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSAKSZone'
  params:{
    privateDNSZoneName: 'privatelink.${location}.azmk8s.io'
  }
}

//aks hub link
module aksHubLink 'modules/vnet/privatdnslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksHubLink'
  params:{
    privateDNSZoneName: privateDNSAKSZone.outputs.privateDNSZoneName
    vnetId: vnetHub.outputs.vnetId
  }
}

//aks identity
module aksIdentity 'modules/identity/userassigned.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksIdentity'
  params:{
    baseName: baseName
    location: location
  }
}

//aks cluster
module aksCluster 'modules/aks/privateaks.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksCluster'
  params:{
    location: location
    aadGroupIds: aadGroupdIds
    baseName: baseName
    logworkspaceId: akslaws.outputs.laWsId
    privateDNSZoneId: privateDNSAKSZone.outputs.privateDNSZoneId
    subnetId: subnetaks.id
    identity: {
      '${aksIdentity.outputs.identityId}' : {}
    }
    principalId: aksIdentity.outputs.principalid
  }
}

//subnet VM
resource subnetVM 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetHub.outputs.vnetName}/vmsubnet'
}

//jumpbox
module jumpbox 'modules/VM/virtualmachine.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'jumpbox'
  params:{
    location: location
    subnetId: subnetVM.id
    publicKey: pubkeydata
    script64: script64
  }
}

//public IP Bastion
module publicIpBastion 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'publicIpBastion'
  params:{
    location: location
    publicIpName: 'bastion-pip'
    publicIpProperties: {
      publicIPAllocationMethod: 'static'
    }
    publicIpSku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

//subnet bastion
resource subnetbastion 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetHub.outputs.vnetName}/AzureBastionSubnet'
}

//Bastion
module bastion 'modules/VM/bastion.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'bastion'
  params:{
    location: location
    bastionIpId: publicIpBastion.outputs.publicIpId
    subnetId: subnetbastion.id
  }
}
