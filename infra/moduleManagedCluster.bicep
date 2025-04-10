// param location string = resourceGroup().location
// param clusterName string



// resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
//   name: clusterName
//   location: location
//   identity: {
//     type: 'SystemAssigned'
//   }
//   properties: {
//     dnsPrefix: '${clusterName}-dns'
//     agentPoolProfiles: [
//       {
//         name: 'agentpool'
//         osDiskSizeGB: 128
//         count: 1
//         vmSize: 'Standard_DS2_v2'
//         osType: 'Linux'
//         mode: 'System'
        
//       }
//     ]
//   }
// }

// output controlPlaneFQDN string = aks.properties.fqdn
