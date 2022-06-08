$baseline='mbn'
$location='eastus'

# Create base64 script value
$script64=$(Get-Content script.sh)
$encScript=[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($script64))

# Generate SSH keypair and pass to public key as parameter
ssh-keygen -m PEM -t rsa -b 4096  -f ./mbnsshkey.pem
$pubkeydata=$(Get-Content mbnsshkey.pem.pub)

$aad="e822cf30-7f5e-4968-a215-5cc48d538580" | ConvertTo-Json
# Create/Update Deployment (replace aad group ID)
az deployment sub create -n "Dep-$baseline" -l $location -f main.bicep --parameters baseName=$baseline --parameters location=$location --parameters script64=$encScript --parameters pubkeydata=$pubkeydata --parameters aadids=$aad

# Attach ACR and get ACR Name
az aks update -n "$baselineaks" -g "rg-$baseline" --attach-acr "acr-$baseline-bicep"

# Get Credentials
az aks get-credentials -n "aks-$baseline" -g "rg-$baseline"