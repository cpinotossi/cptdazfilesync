# Azure Filesync demo
This files contains the pwsh commands to log into the corresponding VMs.

### Prerequisites

~~~powershell
$PSVersionTable.PSVersion
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
Connect-AzAccount
Set-AzContext -Subscription sub-myedge-01
# Install-Module -Name Az.StorageSync -RequiredVersion 1.7.0 -force
Install-Module Az.StorageSync -force -AllowClobber -RequiredVersion 1.7.0
Get-InstalledModule -Name "Az"
Get-InstalledModule -Name "Az.StorageSync"
change its InstallationPolicy value by running the
Set-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2/ -InstallationPolicy Trusted

Set-PSRepository cmdlet. Are you sure you want to install the modules from 'PSGallery'?
Update-Module -force -Scope CurrentUser
A
# Define env variables
$prefix="cptdazfilesync"
$dcvmname="dc-01-win-vm"
$win1vmname="client-01-win-vm"
$win2vmname="cptdvnetwin"
$dcrg="file-rg"
$dcvnetname="file-rg-vnet"
$location="westeurope"
$myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv)
~~~

### Create Azure FileSync service instance

NOTE: We are going to use cloud shell with powershell. My local Powershell installation does have some issues.

~~~powershell
$storageSync = New-AzStorageSyncService -ResourceGroupName $prefix -Name $prefix -Location $location
$storageSync = Get-AzStorageSyncService -ResourceGroupName $prefix -Name $prefix
$syncGroup = New-AzStorageSyncGroup -ParentObject $storageSync -Name $prefix
$storageAccount = Get-AzStorageAccount -ResourceGroupName $prefix -StorageAccountName $prefix
$fileShare = Get-AzStorageShare -Context $storageAccount.Context -Name $prefix 
# Create the cloud endpoint
New-AzStorageSyncCloudEndpoint -Name $prefix -ParentObject $syncGroup -StorageAccountResourceId $storageAccount.Id -AzureFileShareName $fileShare.Name
~~~

### Connect to Domain Controller via rdp

~~~powershell
$dcvmid=$(az vm show -g $dcrg -n $dcvmname --query id -o tsv)
az network bastion rdp -n $prefix -g $dcrg --target-resource-id $dcvmid
~~~

User: 
- admin (local)
- admin@myedge.org (domain joined)

### Connect to Windows Client via rdp

~~~powershell
# Windows Client
$win1vmid=$(az vm show -g $dcrg -n $win1vmname --query id -o tsv)
az network bastion rdp -n $prefix -g $dcrg --target-resource-id $win1vmid
# Windows Fileserver
$win2vmid=$(az vm show -g $dcrg -n $prefix --query id -o tsv)
az network bastion rdp -n $prefix -g $dcrg --target-resource-id $win2vmid
~~~

### Mount Share 
~~~~
net use s: \\cptdazfilesync\
~~~~

### Detect changes
To detect changes to the Azure file share, Azure File Sync has a scheduled job called a change detection job. A change detection job enumerates every file in the file share, and then compares it to the sync version for that file. When the change detection job determines that files have changed, Azure File Sync initiates a sync session. The change detection job is initiated every 24 hours. Because the change detection job works by enumerating every file in the Azure file share, change detection takes longer in larger namespaces than in smaller namespaces. For large namespaces, it might take longer than once every 24 hours to determine which files have changed.

To immediately sync files that are changed in the Azure file share, the Invoke-AzStorageSyncChangeDetection PowerShell cmdlet can be used to manually initiate the detection of changes in the Azure file share. This cmdlet is intended for scenarios where some type of automated process is making changes in the Azure file share or the changes are done by an administrator (like moving files and directories into the share). For end user changes, the recommendation is to install the Azure File Sync agent in an IaaS VM and have end users access the file share through the IaaS VM. This way all changes will quickly sync to other agents without the need to use the Invoke-AzStorageSyncChangeDetection cmdlet. To learn more, see the Invoke-AzStorageSyncChangeDetection documentation.
Based on 
- https://learn.microsoft.com/en-us/powershell/module/az.storagesync/invoke-azstoragesyncchangedetection?view=azps-9.1.0
- https://learn.microsoft.com/en-us/azure/storage/file-sync/file-sync-troubleshoot-sync-errors?tabs=portal1%2Cazure-portal#sync-health

~~~powershell
Get-AzStorageSyncCloudEndpoint
 -ResourceGroupName $prefix -StorageSyncServiceName $prefix -SyncGroupName $prefix
Invoke-AzStorageSyncChangeDetection -ResourceGroupName $prefix -StorageSyncServiceName $prefix -SyncGroupName $prefix -CloudEndpointName "b38fc242-8100-4807-89d0-399cef5863bf"
Invoke-AzStorageSyncChangeDetection -ResourceGroupName $prefix -StorageSyncServiceName $prefix -SyncGroupName $prefix -Name $prefix
~~~

Get-StorageSyncHeatStoreInformation -VolumePath D:\ -ReportDirectoryPath C:\temp -Limit 1000

https://github.com/Azure/azure-rest-api-specs/tree/main/specification/storagesync/resource-manager
https://github.com/Azure/azure-powershell/tree/main/src/StorageSync



WARNING: The version '2.2.5' of module 'PowerShellGet' is currently in use. Retry the operation after closing the applications.
WARNING: The version '2.2.6' of module 'PSReadLine' is currently in use. Retry the operation after closing the applications.
PackageManagement\Install-Package : The version '1.0.2' of the module 'Az.DataLakeAnalytics' being installed is not catalog signed. Ensure that the     version '1.0.2' of the module 'Az.DataLakeAnalytics' has the catalog file 'Az.DataLakeAnalytics.cat' and signed with the same publisher 'CN=Microsoft   Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US' as the previously-installed module 'Az.DataLakeAnalytics' with version '1.0.2'     under the directory 'C:\Users\chpinoto\scoop\modules\AzureRM\Az.DataLakeAnalytics\1.0.2'. If you still want to install or update, use                   -SkipPublisherCheck parameter.                                                                                                                          At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2.5\PSModule.psm1:13069 char:20                                                           + ...           $sid = PackageManagement\Install-Package @PSBoundParameters                                                                             
+                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Microsoft.Power....InstallPackage:InstallPackage) [Install-Package], Exception
    + FullyQualifiedErrorId : ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPack  
   age

PackageManagement\Install-Package : The version '1.0.2' of the module 'Az.DataLakeAnalytics' being installed is not catalog signed. Ensure that the     version '1.0.2' of the module 'Az.DataLakeAnalytics' has the catalog file 'Az.DataLakeAnalytics.cat' and signed with the same publisher 'CN=Microsoft   Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US' as the previously-installed module 'Az.DataLakeAnalytics' with version '1.0.2'     under the directory 'C:\Users\chpinoto\scoop\modules\AzureRM\Az.DataLakeAnalytics\1.0.2'. If you still want to install or update, use                   -SkipPublisherCheck parameter.                                                                                                                          At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2.5\PSModule.psm1:13069 char:20                                                           + ...           $sid = PackageManagement\Install-Package @PSBoundParameters                                                                             
+                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Microsoft.Power....InstallPackage:InstallPackage) [Install-Package], Exception
    + FullyQualifiedErrorId : ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPack  
   age
                                                                                                                                                        PackageManagement\Install-Package : The version '1.1.2' of the module 'Az.Dns' being installed is not catalog signed. Ensure that the version '1.1.2'   of the module 'Az.Dns' has the catalog file 'Az.Dns.cat' and signed with the same publisher 'CN=Microsoft Corporation, O=Microsoft Corporation,         L=Redmond, S=Washington, C=US' as the previously-installed module 'Az.Dns' with version '1.1.2' under the directory                                     'C:\Users\chpinoto\scoop\modules\AzureRM\Az.Dns\1.1.2'. If you still want to install or update, use -SkipPublisherCheck parameter.                      At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2.5\PSModule.psm1:13069 char:20                                                           + ...           $sid = PackageManagement\Install-Package @PSBoundParameters                                                                             
+                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Microsoft.Power....InstallPackage:InstallPackage) [Install-Package], Exception
    + FullyQualifiedErrorId : ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPack  
   age
                                                                                                                                                        PackageManagement\Install-Package : The version '1.1.1' of the module 'Az.Media' being installed is not catalog signed. Ensure that the version         '1.1.1' of the module 'Az.Media' has the catalog file 'Az.Media.cat' and signed with the same publisher 'CN=Microsoft Corporation, O=Microsoft          Corporation, L=Redmond, S=Washington, C=US' as the previously-installed module 'Az.Media' with version '1.1.1' under the directory                      'C:\Users\chpinoto\scoop\modules\AzureRM\Az.Media\1.1.1'. If you still want to install or update, use -SkipPublisherCheck parameter.                    At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2.5\PSModule.psm1:13069 char:20                                                           + ...           $sid = PackageManagement\Install-Package @PSBoundParameters                                                                             
+                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Microsoft.Power....InstallPackage:InstallPackage) [Install-Package], Exception
    + FullyQualifiedErrorId : ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPack  
   age

PackageManagement\Install-Package : The version '1.1.1' of the module 'Az.NotificationHubs' being installed is not catalog signed. Ensure that the      version '1.1.1' of the module 'Az.NotificationHubs' has the catalog file 'Az.NotificationHubs.cat' and signed with the same publisher 'CN=Microsoft     Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US' as the previously-installed module 'Az.NotificationHubs' with version '1.1.1'      under the directory 'C:\Users\chpinoto\scoop\modules\AzureRM\Az.NotificationHubs\1.1.1'. If you still want to install or update, use                    -SkipPublisherCheck parameter.                                                                                                                          At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2.5\PSModule.psm1:13069 char:20                                                           + ...           $sid = PackageManagement\Install-Package @PSBoundParameters                                                                             
+                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Microsoft.Power....InstallPackage:InstallPackage) [Install-Package], Exception
    + FullyQualifiedErrorId : ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPack  
   age
                                                                                                                                                        PackageManagement\Install-Package : The version '1.0.3' of the module 'Az.Relay' being installed is not catalog signed. Ensure that the version         '1.0.3' of the module 'Az.Relay' has the catalog file 'Az.Relay.cat' and signed with the same publisher 'CN=Microsoft Corporation, O=Microsoft          Corporation, L=Redmond, S=Washington, C=US' as the previously-installed module 'Az.Relay' with version '1.0.3' under the directory                      'C:\Users\chpinoto\scoop\modules\AzureRM\Az.Relay\1.0.3'. If you still want to install or update, use -SkipPublisherCheck parameter.                    At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2.5\PSModule.psm1:13069 char:20                                                           + ...           $sid = PackageManagement\Install-Package @PSBoundParameters                                                                             
+                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Microsoft.Power....InstallPackage:InstallPackage) [Install-Package], Exception
    + FullyQualifiedErrorId : ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPack  
   age                                                                                                                                                                                                                                                                                                          PackageManagement\Install-Package : Administrator rights are required to install or update. Log on to the computer with an account that has             Administrator rights, and then try again, or install by adding "-Scope CurrentUser" to your command. You can also try running the Windows PowerShell    session with elevated rights (Run as Administrator).                                                                                                    At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2.5\PSModule.psm1:13069 char:20                                                           + ...           $sid = PackageManagement\Install-Package @PSBoundParameters                                                                             +                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                                             
    + CategoryInfo          : InvalidArgument: (System.Collections.ArrayList:String) [Install-Package], Exception
    + FullyQualifiedErrorId : AdministratorRightsNeededOrSpecifyCurrentUserScope,Copy-Module,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPac  
   kage

WARNING: The version '1.7.0' of module 'Az.StorageSync' is currently in use. Retry the operation after closing the applications.