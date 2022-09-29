
Import-Module ADSync
param(
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "CaPoliciesExport.Container" } )]
    [string] $ContainerName,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "CaPoliciesExport.ResourceGroup" } )]
    [string] $ResourceGroupName,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "CaPoliciesExport.StorageAccount.Name" } )]
    [string] $StorageAccountName,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "CaPoliciesExport.StorageAccount.Location" } )]
    [string] $StorageAccountLocation,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "CaPoliciesExport.StorageAccount.Sku" } )]
    [string] $StorageAccountSku,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

$datestring = (get-date).ToString("ddMMMyyyy")
#is this the staging server
[bool] $staging = $false
[string] $servername = "AADC-SERVER01"
[string] $path = "C:\Users\Administrator\Documents\logs\"
if($staging){
    Get-ADSyncServerConfiguration -Path "$path$servername-staging-$datestring"
}
else {
    Get-ADSyncServerConfiguration -Path "$path$servername-$datestring"
}


Connect-RjRbAzAccount


if (-not $ContainerName) {
    $ContainerName = "office-licensing-v2-" + (get-date -Format "yyyy-MM-dd")
}

# Make sure storage account exists
$storAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
if (-not $storAccount) {
    "## Creating Azure Storage Account $($StorageAccountName)"
    $storAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $StorageAccountLocation -SkuName $StorageAccountSku 
}

# Get access to the Storage Account
$keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $keys[0].Value

# Make sure, container exists
$container = Get-AzStorageContainer -Name $ContainerName -Context $context -ErrorAction SilentlyContinue
if (-not $container) {
    "## Creating Azure Storage Account Container $($ContainerName)"
    $container = New-AzStorageContainer -Name $ContainerName -Context $context 
}

$EndTime = (Get-Date).AddDays(6)

"## Upload"
if ($exportAsZip) {
    $zipFileName = "office-licensing-v2-" + (get-date -Format "yyyy-MM-dd") + ".zip"
    Compress-Archive -Path $OutPutPath -DestinationPath $zipFileName | Out-Null
    Set-AzStorageBlobContent -File $zipFileName -Container $ContainerName -Blob $zipFileName -Context $context -Force | Out-Null
    if ($produceLinks) {
        #Create signed (SAS) link
        $SASLink = New-AzStorageBlobSASToken -Permission "r" -Container $ContainerName -Context $context -Blob $zipFileName -FullUri -ExpiryTime $EndTime
        "$SASLink"
    }
    "## '$zipFileName' upload successful."
}
else {
    # Upload all files individually
    Get-ChildItem -Path $OutPutPath | ForEach-Object {
        Set-AzStorageBlobContent -File $_.FullName -Container $ContainerName -Blob $_.Name -Context $context -Force | Out-Null
        if ($produceLinks) {
            #Create signed (SAS) link
            $SASLink = New-AzStorageBlobSASToken -Permission "r" -Container $ContainerName -Context $context -Blob $_.Name -FullUri -ExpiryTime $EndTime
            "## $($_.Name)"
            " $SASLink"
            ""
        }
    }
    "## upload of CSVs successful."
}
if ($produceLinks) {
    ""
    "## Expiry of Links: $EndTime"
}