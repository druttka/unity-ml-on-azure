# unity-ml-on-azure
Resources for running Unity ML agent training in Azure

## Prerequisites
- Unity 3D with [ML Agents](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Getting-Started-with-Balance-Ball.md)
- An Azure account; get [free Azure credits](https://azure.microsoft.com/Credits/Free)!
- The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [PowerShell](https://github.com/powershell/powershell#get-powershell); bash support coming very soon

## Quickstart
1. Get started with Unity 3D ML Agents as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Getting-Started-with-Balance-Ball.md)
1. Build your Unity project for Linux x86_64 as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Using-Docker.md)
1. Copy `scripts/train-on-aci.ps1` to the directory which contains the Unity build artifacts (e.g, the x86_64 file and _Data directory) 
1. Run the following
```
az login
./train-on-aci.ps1 -storageAccountName {globallyUniqueStorageAccountName}
```

## Details
`scripts/train-on-aci.ps1` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Container Instance to run the ML training using said Unity build, outputting to said file share

## Parameters
See comment based help in [train-on-aci.ps1](./scripts/train-on-aci.ps1).