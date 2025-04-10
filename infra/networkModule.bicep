param location string
param vnetName string
param logAnalyticsWorkspaceId string
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
      name: 'AzureBastionSubnet'
      properties: {
        addressPrefix: '10.0.0.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      }
      {
      name: 'private-endpoint'
      properties: {
        addressPrefix: '10.0.1.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      }
      {
        name: 'vm-endpoint'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        }
        {
          name: 'aks-01'
          properties: {
            addressPrefix: '10.0.3.0/24'
            privateEndpointNetworkPolicies: 'Disabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
          }
          }
    ]
  }
  tags: tags
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output bastionSubnetId string = vnet.properties.subnets[0].id
output privateEndpointSubnetId string = vnet.properties.subnets[1].id
output vmSubnetId string = vnet.properties.subnets[2].id
output aksSubnetId string = vnet.properties.subnets[3].id

