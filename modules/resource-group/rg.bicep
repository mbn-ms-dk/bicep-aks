targetScope = 'subscription'
param location string 
param rgName string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: rgName
}

output rgId string = rg.id
output rgName string = rg.name
