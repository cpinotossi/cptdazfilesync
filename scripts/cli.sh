dcvnetid=$(az network vnet show -n $dcvnetname -g $dcrg --query id -o tsv)
az network vnet peering create -n ${prefix}v2dc --remote-vnet $dcvnetid -g $prefix --vnet-name $prefix --allow-forwarded-traffic --allow-vnet-access
vnetid=$(az network vnet show -n $prefix -g $prefix --query id -o tsv)
az network vnet peering create -n ${prefix}dc2v --remote-vnet $vnetid -g $dcrg --vnet-name $dcvnetname --allow-forwarded-traffic --allow-vnet-access