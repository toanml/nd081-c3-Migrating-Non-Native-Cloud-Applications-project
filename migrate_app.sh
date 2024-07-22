# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
resourceGroup="resourcegroup-nd081-c3-$randomIdentifier"
location="eastus"
tag="create-postgresql-server-and-firewall-rule"
server="postgres-server-mlt"
sku="GP_Gen5_2"
login="azureuser"
password="PaSSw0rD"
startIp=0.0.0.0
endIp=255.255.255.255

servicebusName="azure-servicebus-mlt"
serviceQueueName="notificationqueue"
storageAccountName="storageaccountmlt"
storageQueueName="storagequeuemlt"

appserviceplan="appserviceplanmlt"
appservice="appservicemlt"

functionApp="functionappmlt"
functionsVersion="4"
pythonVersion="3.11"

# create an Azure resource group
echo "Creating resource group $resourceGroup in $location"
az group create --name $resourceGroup --location "$location"

# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az postgres server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# Configure a firewall rule for the server 
echo "Configuring a firewall rule for $server for the IP address range of $startIp to $endIp"
az postgres server firewall-rule create --resource-group $resourceGroup --server $server --name AllowIps --start-ip-address $startIp --end-ip-address $endIp

# create a Service Bus messaging namespace
echo "Create servicebus $servicebusName"
az servicebus namespace create --resource-group $resourceGroup --name "$servicebusName" --location "$location"

# create a queue in the namespace
echo "Create service queue $serviceQueueName"
az servicebus queue create --resource-group $resourceGroup --namespace-name "$servicebusName" --name "$serviceQueueName"

# create a storage account
echo "Create storage account $storageAccountName"
az storage account create -n $storageAccountName -g $resourceGroup -l $location --sku Standard_LRS

# create a storage queue
echo "Create storage queue $storageQueueName"
az storage queue create -n $storageQueueName --metadata key1=value1 key2=value2 --account-name $storageAccountName

# Get service bus connection string
# service bus namespace/settings/shared access policies


# Create app service plan
echo "Create app service plan $appserviceplan"
az appservice plan create --name $appserviceplan --resource-group $resourceGroup --is-linux --sku F1

echo "Create app service $appservice"
az webapp create --name $appservice --resource-group $resourceGroup --plan $appserviceplan --runtime "PYTHON:3.11"

echo "Verify app service"
az webapp show --name $appservice --resource-group $resourceGroup

# Create a serverless function app in the resource group.
echo "Creating $functionApp"
az functionapp create --name $functionApp --storage-account $storageAccountName --consumption-plan-location "$location" --resource-group $resourceGroup --os-type Linux --runtime python --runtime-version $pythonVersion --functions-version $functionsVersion