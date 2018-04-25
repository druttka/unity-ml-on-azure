: '
    Deploys a Unity 3D environment for ML training in Azure
    DESCRIPTION
    This script ensures the presence of Azure resources (e.g., resource group, storage account, file share) and then copies the Unity build output to Azure. It then creates and Azure Container Instance to run the ML training and store the models and summaries in the same Azure File Share.
        PARAMETER storageAccountName
            Required. Must be globally unique. This storage account will be used for the Azure File Share to which Unity build output and trained models are published.
        PARAMETER environmentName
            The environment name (e.g., 3dball) to deploy and train. This can be omitted and automatically detected if your build directory only contains one environment.
        PARAMETER localVolume
            The local directory which contains the build output (i.e., which contains the .x86_64 file and _Data folder). This can be omitted and automatically detected if the script is run from the build output directory or a parent directory of the build output.
        PARAMETER runId
            A run identifier for the training. If omitted, a timestamp of the format YYYYMMddHHmm will be used.
        PARAMETER resourceGroupName
            The name of the Azure resource group. If omitted, this will be defaulted to unityml.
        PARAMETER location
            The target Azure region. If omitted, westus2 is used. Azure Container Instances must be supported in the region; see https://azure.microsoft.com/en-us/global-infrastructure/services/
        PARAMETER storageShareName
            The name of the file share inside the Azure Storage account. Defaults to unityml.
        PARAMETER containerImage
            The Docker container image which contains the python resources to run the training. Defaults to druttka/unity-ml-trainer:latest. To build your own container, see https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Using-Docker.md
    EXAMPLE
        ./train-on-aci.sh -storageAccountName "drunityml20180425"
    LINK
        https://github.com/druttka/unity-ml-on-azure
'


if [ $# -lt "1" ]; then
        echo "Usage:  $0 --StorageAccountName <name>"
        exit 1;
fi

# Loop through parameters and save to variables
# From https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts
while [ $# -gt 0 ]; do

   if [[ $1 == "-"* ]]; then
        v="${1/-/}"
        declare $v="$2"
   fi
  shift
done

if [ -z "$storageAccountName" ] && [ -z "$san" ]; then
    echo "You must pass a storage account name in."
    exit 1;
fi

# Make sure $StorageAccountName is set
if [ -z "$storageAccountName" ]; then
    storageAccountName=$san
fi

# Check for variables and set defaults
if [ -z "$resourceGroupName" ]; then
    resourceGroupName="unityml"
fi
if [ -z "$location" ]; then
    location="westus2"
fi
if [ -z "$storageShareName" ]; then
    storageShareName="unityml"
fi
if [ -z "$containerImage" ]; then
    containerImage="druttka/unity-ml-trainer:latest"
fi
if [ -z "$runId" ]; then
    runId=`date '+%Y%m%d%H%M'`
fi
if [ -z "$localPath" ]; then
    testPath=$PWD
else
    testPath=$localPath
fi

# Find valid files
environments=( $(find $testPath -type f -name "*.x86_64") )

# Check for no Environments and multiple Environments
if [ ${#environments[*]} == 0 ]; then
    echo "No environments found under $testPath. Provide the \$localVolume argument to specify the location of build artifacts."
    exit 1;
elif [ -z "$environmentName" ] && [ ${#environments[*]} != 1 ]; then
    echo "Found multiple environments in $testPath. Provide the \$environmentName and/or \$localVolume arguments to specify the target environment."
    exit 1;
fi

if [ -z "$environmentName" ] && [ ${#environments[*]} == 1 ]; then
    environmentName=$(basename ${environments[0]})
    localVolume=${environments[0]%/*} 
elif ! [[ -z "$environmentName" ]]; then

    for ((i=0; i < ${#environments[*]} ; i++))
    do        
        filebase=${environments[$i]##*/}
        nameNoExtension=${filebase%.*}
        if [ $nameNoExtension = $environmentName ]; then
            environmentFound=1
            environmentName=$(basename ${environments[$i]})
            localVolume=${environments[$i]%/*} 
            break
        fi
    done
    if [ -z "$environmentFound" ]; then
        echo "Did not find $environmentName. Check the values of \$environmentName and \$localVolume, or omit them to attempt automatic detection."
        exit 1
    fi
fi

echo "Using $environmentName, in $localVolume."

# Create our Azure Resources as needed
az group create --name $resourceGroupName --location $location
az storage account create --resource-group $resourceGroupName --name $storageAccountName --location $location --sku Standard_LRS --kind Storage
# Get primary storage account key
storageAccountKey=$(az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query [0].value --output tsv)
# Create storage share
az storage share create --name $storageShareName --quota 2048 --account-name $storageAccountName --account-key $storageAccountKey
# TODO: When running on mac, this will also upload the DS_Store folder.  Not harmful but we should ignore or delete before upload possibly
az storage file upload-batch --account-name $storageAccountName --account-key $storageAccountKey --destination $storageShareName --source $localVolume
aciName="unityml$runId"

# Create and Run container
az container create \
    --resource-group $resourceGroupName \
    --name $aciName \
    --location $location \
    --image $containerImage \
    --azure-file-volume-account-name $storageAccountName \
    --azure-file-volume-account-key $storageAccountKey \
    --azure-file-volume-share-name $storageShareName \
    --azure-file-volume-mount-path /unity-volume \
    --restart-policy OnFailure \
    --command-line "python python/learn.py $environmentName --docker-target-name=unity-volume --train --run-id=$runId"

az container attach --resource-group $resourceGroupName --name $aciName
az container delete --resource-group $resourceGroupName --name $aciName -y