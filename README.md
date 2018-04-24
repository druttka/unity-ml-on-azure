# unity-ml-on-azure
Resources for running Unity ML agent training in Azure

## Prerequisites
- Unity 3D with [ML Agents](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Getting-Started-with-Balance-Ball.md)
- An Azure account; get [free Azure credits](https://azure.microsoft.com/Credits/Free)!
- The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [PowerShell](https://github.com/powershell/powershell#get-powershell); bash support coming very soon

## Quickstart
1. Get started with Unity 3D ML Agents as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Getting-Started-with-Balance-Ball.md)
1. Build your Unity project for Linux x86_x64 as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Using-Docker.md)
1. `az login` and `az account set` to set your account context
1. Run the following
```
./train-on-aci.ps1 -resourceGroupName {yourResourceGroupName} -location {targetLocation} -storageAccountName {yourStoAcct} -storageShareName {yourFileShareName} -environmentName {yourUnityExeName} -runId {uniqueRunId} -localVolume {pathToUnityBuildOutput}`
```

## Details
`scripts/train-on-aci.ps1` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Container Instance to run the ML training using said Unity build, outputting to said file share

## Parameters

### PowerShell
- `[string]$resourceGroupName`: the name of the target resource group
- `[string]$location`: the target Azure region
- `[string]$storageAccountName`: the name of the target storage account
- `[string]$storageShareName`: the name of the target file share
- `[string]$environmentName`: the filename of your Unity build output (e.g., '3dball')
- `[string]$runId`: a unique identifier for the training run; if you don't make this unique, your models will overwrite themselves
- `[string]$localVolume`: the path on your local file system which contains the Unity build output (e.g., `<env>.x86_64` and `<env>_Data\`)
