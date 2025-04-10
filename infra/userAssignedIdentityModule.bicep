@description('The location where the user-assigned managed identity will be created')
param location string

@description('The name of the user-assigned managed identity')
param identityName string

@description('Tags to apply to the user-assigned managed identity')
param tags object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
  tags: tags
}

output identityResourceId string = userAssignedIdentity.id
output identityClientId string = userAssignedIdentity.properties.clientId
