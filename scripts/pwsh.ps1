$storageSync = New-AzStorageSyncService -ResourceGroupName "${Env:prefix}" -Name "${Env:prefix}" -Location "${Env:location}"
$syncGroup = New-AzStorageSyncGroup -ParentObject $storageSync -Name "${Env:prefix}"
# Get or create a storage account with desired name
$storageAccountName = "${Env:prefix}"
$storageAccount = Get-AzStorageAccount -ResourceGroupName "${Env:prefix}" | Where-Object {
    $_.StorageAccountName -eq "${Env:prefix}"
}
# Get or create an Azure file share within the desired storage account
$fileShareName = "${Env:prefix}"
$fileShare = Get-AzStorageShare -Context $storageAccount.Context | Where-Object {
    $_.Name -eq $fileShareName -and $_.IsSnapshot -eq $false
}
# Create the cloud endpoint
New-AzStorageSyncCloudEndpoint `
    -Name $fileShare.Name `
    -ParentObject $syncGroup `
    -StorageAccountResourceId $storageAccount.Id `
    -AzureFileShareName $fileShare.Name