targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
var dcvnetname = 'file-rg-vnet'
var dcrgname = 'file-rg'
param prefix string
param myobjectid string
param myip string

module saf 'azbicep/bicep/saf.bicep' = {
  name: '${prefix}safdeploy'
  params: {
    location: location
    myip: myip
    myObjectId: myobjectid
    prefix: prefix
  }
}

// module vnet 'azbicep/bicep/vnet.bicep' = {
//   name: '${prefix}vnetdeploy'
//   params: {
//     cidersubnet: '10.0.0.0/24'
//     cidervnet: '10.0.0.0/16'
//     ciderbastion: '10.0.1.0/24'
//     location: location 
//     prefix: prefix
//     // dnsip: dcdnsip
//   }
// }

// resource dcvnet 'Microsoft.ScVmm/virtualNetworks@2020-06-05-preview' existing = {
//   name: dcvnetname
//   scope: resourceGroup(dcrgname)
// }

// resource runcli 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: '${prefix}runclideploy'
//   location: location
//   kind: 'AzureCLI'
//   properties: {
//     azCliVersion: '2.42.0'
//     retentionInterval: 'P1D'
//     environmentVariables:[
//       {
//         name: 'prefix'
//         value:prefix
//       }
//       {
//         name: 'dcvnetname'
//         value: dcvnetname
//       }
//     ]
//     scriptContent:'az network vnet peering create -n ${prefix}v2dc --remote-vnet $dcvnetname -g $prefix --vnet-name $prefix --allow-forwarded-traffic true --allow-vnet-access true'
//   }
//   dependsOn:[
//     vnet
//   ]
// }

resource runpwsh 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${prefix}runpwshdeploy'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '8.0'
    environmentVariables: [
      {
        name: 'prefix'
        value: prefix
      }
      {
        name: 'location'
        value: location
      }
    ]
    scriptContent: loadTextContent('./scripts/pwsh.ps1')
    timeout: 'PT4H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
