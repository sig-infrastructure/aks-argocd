targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string
// param myPublicIp string

@minLength(1)
@description('Primary location for all resources')
param location string

var tags = {
  'azd-env-name': environmentName
}

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

param principalId string

// @secure()
// param kubeConfig string

// extension kubernetes with {
//   namespace: 'default'
//   kubeConfig: kubeConfig
// } as k8s


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

module logAnalyticsWorkspaceModule 'logAnalyticsWorkspaceModule.bicep' = {
  name: 'logAnalyticsWorkspaceModule'
  scope: rg
  params: {
    location: location
    tags: tags
    workspaceName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    
  }
}

module userAssignedIdentityModule 'userAssignedIdentityModule.bicep' = {
  name: 'userAssignedIdentityModule'
  scope: rg
  params: {
    location: location
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
    tags: tags
  }
}


module networkModule 'networkModule.bicep' = {
  name: 'networkModule'
  scope: rg
  params: {
    location: location
    vnetName: '${abbrs.networkVirtualNetworks}${resourceToken}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceModule.outputs.workspaceId
    tags: tags
  }
}

module vault 'br/public:avm/res/key-vault/vault:0.11.0' = {
  name: 'vaultDeployment'
  scope: rg
  params: {
    // Required parameters
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    // Non-required parameters
    enablePurgeProtection: false
  }
}


// module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.8.3' = {
  module managedCluster './modules/container-service/managed-cluster/main.bicep' = {
  name: 'managedClusterDeployment-mgmt'
  scope: rg
  params: {
    // Required parameters
    name: '${abbrs.containerServiceManagedClusters}-mgmt-${resourceToken}'
    kubernetesVersion: '1.31.7'
    publicNetworkAccess: 'Enabled'
    primaryAgentPoolProfiles: [
      {
        orchestratorVersion: '1.31.7'
        availabilityZones: [
          3
        ]
        count: 1
        enableAutoScaling: true
        maxCount: 3
        maxPods: 30
        minCount: 1
        mode: 'System'
        name: 'systempool'
        
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        osDiskSizeGB: 0
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_B2s'
        vnetSubnetResourceId: networkModule.outputs.aksSubnetId
      }
    ]
    // Non-required parameters
    aadProfile: {
      aadProfileEnableAzureRBAC: true
      aadProfileManaged: true
    }
    agentPools: [
      {
        orchestratorVersion: '1.31.7'
        availabilityZones: [
          3
        ]
        count: 2
        enableAutoScaling: true
        maxCount: 3
        maxPods: 30
        minCount: 1
        minPods: 2
        mode: 'User'
        name: 'userpool1'
        nodeLabels: {}
        osDiskSizeGB: 128
        osType: 'Linux'
        // proximityPlacementGroupResourceId: '<proximityPlacementGroupResourceId>'
        scaleSetEvictionPolicy: 'Delete'
        scaleSetPriority: 'Regular'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_B2s'
        vnetSubnetResourceId: networkModule.outputs.aksSubnetId
      }
      // {
      //   availabilityZones: [
      //     3
      //   ]
      //   count: 2
      //   enableAutoScaling: true
      //   maxCount: 3
      //   maxPods: 30
      //   minCount: 1
      //   minPods: 2
      //   mode: 'User'
      //   name: 'userpool2'
      //   nodeLabels: {}
      //   osDiskSizeGB: 128
      //   osType: 'Linux'
      //   scaleSetEvictionPolicy: 'Delete'
      //   scaleSetPriority: 'Regular'
      //   type: 'VirtualMachineScaleSets'
      //   vmSize: 'Standard_DS4_v2'
      //   vnetSubnetResourceId: networkModule.outputs.aksSubnetId
      // }
    ]
    autoNodeOsUpgradeProfileUpgradeChannel: 'Unmanaged'
    autoUpgradeProfileUpgradeChannel: 'stable'
    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'customSetting'
        workspaceResourceId: logAnalyticsWorkspaceModule.outputs.workspaceId
      }
    ]
    // diskEncryptionSetResourceId: '<diskEncryptionSetResourceId>'
    enableAzureDefender: true
    enableAzureMonitorProfileMetrics: true
    enableKeyvaultSecretsProvider: true
    enableOidcIssuerProfile: true
    enablePodSecurityPolicy: false
    enableStorageProfileBlobCSIDriver: true
    enableStorageProfileDiskCSIDriver: true
    enableStorageProfileFileCSIDriver: true
    enableStorageProfileSnapshotController: true
    enableWorkloadIdentity: true
    // fluxExtension: {
    //   configurations: [
    //     {
    //       gitRepository: {
    //         repositoryRef: {
    //           branch: 'main'
    //         }
    //         sshKnownHosts: ''
    //         syncIntervalInSeconds: 300
    //         timeoutInSeconds: 180
    //         url: 'https://github.com/mspnp/aks-baseline'
    //       }
    //       kustomizations: {
    //         unified: {
    //           path: './cluster-manifests'
    //         }
    //       }
    //       namespace: 'flux-system'
    //       scope: 'cluster'
    //     }
    //     {
    //       gitRepository: {
    //         repositoryRef: {
    //           branch: 'main'
    //         }
    //         sshKnownHosts: ''
    //         syncIntervalInSeconds: 300
    //         timeoutInSeconds: 180
    //         url: 'https://github.com/Azure/gitops-flux2-kustomize-helm-mt'
    //       }
    //       kustomizations: {
    //         apps: {
    //           dependsOn: [
    //             'infra'
    //           ]
    //           path: './apps/staging'
    //           prune: true
    //           retryIntervalInSeconds: 120
    //           syncIntervalInSeconds: 600
    //           timeoutInSeconds: 600
    //         }
    //         infra: {
    //           dependsOn: []
    //           path: './infrastructure'
    //           prune: true
    //           syncIntervalInSeconds: 600
    //           timeoutInSeconds: 600
    //           validation: 'none'
    //         }
    //       }
    //       namespace: 'flux-system-helm'
    //       scope: 'cluster'
    //     }
    //   ]
    //   configurationSettings: {
    //     'helm-controller.enabled': 'true'
    //     'image-automation-controller.enabled': 'false'
    //     'image-reflector-controller.enabled': 'false'
    //     'kustomize-controller.enabled': 'true'
    //     'notification-controller.enabled': 'true'
    //     'source-controller.enabled': 'true'
    //   }
    // }
    identityProfile: {
      kubeletidentity: {
        resourceId: userAssignedIdentityModule.outputs.identityResourceId
        // userAssignedIdentityID: userAssignedIdentityModule.outputs.identityClientId
      }
    }
    location: location
    // lock: {
    //   kind: 'CanNotDelete'
    //   name: 'myCustomLockName'
    // }
    maintenanceConfigurations: [
      {
        maintenanceWindow: {
          durationHours: 4
          schedule: {
            weekly: {
              dayOfWeek: 'Sunday'
              intervalWeeks: 1
            }
          }
          startDate: '2024-07-15'
          startTime: '00:00'
          utcOffset: '+00:00'
        }
        name: 'aksManagedAutoUpgradeSchedule'
      }
      {
        maintenanceWindow: {
          durationHours: 4
          schedule: {
            weekly: {
              dayOfWeek: 'Sunday'
              intervalWeeks: 1
            }
          }
          startDate: '2024-07-15'
          startTime: '00:00'
          utcOffset: '+00:00'
        }
        name: 'aksManagedNodeOSUpgradeSchedule'
      }
    ]
    managedIdentities: {
      userAssignedResourceIds: [
        userAssignedIdentityModule.outputs.identityResourceId
      ]
    }
    monitoringWorkspaceResourceId: logAnalyticsWorkspaceModule.outputs.workspaceId
    networkDataplane: 'azure'
    networkPlugin: 'azure'
    networkPluginMode: 'overlay'
    serviceCidr: '10.200.0.0/16'
    dnsServiceIP: '10.200.0.10'
    omsAgentEnabled: true
    openServiceMeshEnabled: true
    roleAssignments: [
      {
        name: 'ac915208-669e-4665-9792-7e2dc861f569'
        principalId: userAssignedIdentityModule.outputs.identityClientId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Owner'
      }
      {
        name: '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8'
        principalId: principalId
        principalType: 'User'
        roleDefinitionIdOrName: '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8'
      }
      // {
      //   principalId: '<principalId>'
      //   principalType: 'ServicePrincipal'
      //   roleDefinitionIdOrName: '<roleDefinitionIdOrName>'
      // }
    ]
    tags: {
      Environment: 'Non-Prod'
      'hidden-title': 'This is visible in the resource name'
      Role: 'DeploymentValidation'
    }
  }
}


// module kubernetes './aks-store-quickstart.bicep' = {
//   scope: rg
//   name: 'buildbicep-deploy'
//   params: {
//     kubeConfig: module.managedCluster.outputs.kubeConfig
//   }
// }

output RESOURCE_GROUP_NAME string = rg.name
