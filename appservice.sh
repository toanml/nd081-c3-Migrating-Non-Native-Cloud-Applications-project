# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
resourceGroup="resourcegroup-nd081-c3-$randomIdentifier"
location="eastus"

appserviceplan="appserviceplanmlt"
appservice="attendeeservce"

# create an Azure resource group
echo "Creating resource group $resourceGroup in $location"
az group create --name $resourceGroup --location "$location"

# Create app service plan
echo "Create app service plan $appserviceplan"
az appservice plan create --name $appserviceplan --resource-group $resourceGroup --is-linux --sku F1

echo "Create app service $appservice"
az webapp create --name $appservice --resource-group $resourceGroup --plan $appserviceplan --runtime "PYTHON:3.9"
# az webapp create --name $appservice --resource-group $resourceGroup s --sku F1 --runtime "PYTHON:3.9"

echo "Verify app service"
az webapp show --name $appservice --resource-group $resourceGroup