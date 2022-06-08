param subnetId string
param publicKey string
param script64 string
param userName string = 'azureuser'
param location string

module mbnnic '../vnet/nic.bicep' = {
  name: 'mbnnic'
  params: {
    subnetId: subnetId
    location: location
  }
}

//jumpbox
resource jumpbox 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'jumpbox'
  location: location
  properties: {
    osProfile: {
      computerName: 'jumpbox'
      adminUsername: userName
      linuxConfiguration: {
        ssh: {
          publicKeys: [
            {
              path: 'home/azureuser/.ssh/authorized_keys'
              keyData: publicKey
            }
          ]
        }
        disablePasswordAuthentication: true
      }
    }
    hardwareProfile: {
      vmSize: 'Standard_A2'
    }
    storageProfile:{
      osDisk:{
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntuServer'
        sku: '20-04-LTS'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces:[
        {
          id: mbnnic.outputs.nicId
        }
      ]
    }
  }
}

//extensions
resource vmext 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${jumpbox.name}/csscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      script: script64
    }
  }
}
