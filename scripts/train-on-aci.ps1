param(
  [string]$resourceGroupName,
  [string]$location,
  [string]$storageAccountName,
  [string]$storageShareName,
  [string]$environmentName,
  [string]$runId,
  [string]$localVolume
)

# TODO: There seems to be nothing project specific in here
$img="druttka/unity-ml-trainer"

# TODO: Error checking/handling. This is the very happy path starting point 
az group create --name $resourceGroupName --location $location
az storage account create --resource-group $resourceGroupName --name $storageAccountName --location $location --sku Standard_LRS --kind Storage
$keys = (az storage  account keys list --resource-group $resourceGroupName --account-name $storageAccountName --query "[].value" -o tsv)
$storageAccountKey = $keys[0]
az storage share create --name $storageShareName --quota 2048 --account-name $storageAccountName --account-key $storageAccountKey
az storage file upload-batch --account-name $storageAccountName --account-key $storageAccountKey --destination $storageShareName --source $localVolume

# TODO: Cleanup when Terminated
az container create `
    --resource-group $resourceGroupName `
    --name unityml$runId `
    --location $location `
    --image $img `
    --azure-file-volume-account-name $storageAccountName `
    --azure-file-volume-account-key $storageAccountKey `
    --azure-file-volume-share-name $storageShareName `
    --azure-file-volume-mount-path /unity-volume `
    --restart-policy OnFailure `
    --command-line "python python/learn.py $environmentName --docker-target-name=unity-volume --train --run-id=$runId"
