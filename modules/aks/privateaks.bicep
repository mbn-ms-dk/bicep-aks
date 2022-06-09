param baseName string
param aadGroupIds array
param logworkspaceId string
param privateDNSZoneId string
param subnetId string
param identity object
param principalId string
param location string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-03-01' = {
  name: 'aks-${baseName}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: identity
  }
  properties: {
    kubernetesVersion: '1.23.5'
    nodeResourceGroup: 'rg-${baseName}-aksInfra'
    dnsPrefix: '${baseName}aks'
    agentPoolProfiles: [
      {
        name: 'default'
        count: 2
        vmSize: 'standard_dc4ds_v3' //'Standard_D4s_V3'
        mode: 'System'
        maxCount: 5
        minCount: 2
        maxPods: 50
        enableAutoScaling: true
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      outboundType: 'userDefinedRouting'
      dockerBridgeCidr: '172.17.0.1/16'
      dnsServiceIP: '10.0.0.10'
      serviceCidr: '10.0.0.0/16'
      networkPolicy: 'azure'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: privateDNSZoneId
    }
    enableRBAC: true
    aadProfile: {
      adminGroupObjectIDs: aadGroupIds
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
    }
    addonProfiles:{
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: logworkspaceId
        }
        enabled: true
      }
      azurepolicy: {
        enabled: true
      }
    }
  }
}

module aksPrivateDNSZoneContributor '../Identity/role.bicep' = {
  name: 'aksPvtDNSContrib'
  params: {
    principalid: principalId
    roleGuid: 'b12aa53e-6015-4669-85d0-8515ebb3ae7f' //Private DNS Zone Contributor
  }
}

module aksNetworkContributor '../identity/role.bicep' = {
  name: 'aksPrivateDNSContrib'
  params: {
    principalid: principalId
    roleGuid: '4d97b98b-1d4f-4787-a291-c67834d212e7' //Network Contributor
  }
}
