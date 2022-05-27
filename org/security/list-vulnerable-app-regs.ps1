<#
  .SYNOPSIS
  List all app registrations that suffer from the CVE-2021-42306 vulnerability.

  .DESCRIPTION
  List all app registrations that suffer from the CVE-2021-42306 vulnerability.

  .NOTES
  Permissions
   MS Graph (API): 
   - DeviceManagementManagedDevices.Read.All

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "CallerName": {
                "Hide": true
            }
        }
    }

#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }

param(
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "VulnAppRegExport.Container" } )]
    [string] $ContainerName,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "VulnAppRegExport.ResourceGroup" } )]
    [string] $ResourceGroupName,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "VulnAppRegExport.StorageAccount.Name" } )]
    [string] $StorageAccountName,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "VulnAppRegExport.StorageAccount.Location" } )]
    [string] $StorageAccountLocation,
    [ValidateScript( { Use-RJInterface -Type Setting -Attribute "VulnAppRegExport.StorageAccount.Sku" } )]
    [string] $StorageAccountSku,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)


if (-not $ContainerName) {
    $ContainerName = "list-vulnerableappreg"
}

if ((-not $ResourceGroupName) -or (-not $StorageAccountName) -or (-not $StorageAccountSku) -or (-not $StorageAccountLocation)) {
    "## To export to a storage account, please use RJ Runbooks Customization ( https://portal.realmjoin.com/settings/runbooks-customizations ) to specify an Azure Storage Account for upload."
    "## Alternatively, present values for ResourceGroup and StorageAccount when staring the runbook."
    ""
    "## Configure the following attributes:"
    "## - VulnAppRegExport.ResourceGroup"
    "## - VulnAppRegExport.StorageAccount.Name"
    "## - VulnAppRegExport.StorageAccount.Location"
    "## - VulnAppRegExport.StorageAccount.Sku"
    ""
    "## Stopping execution."
    throw "Missing Storage Account Configuration."
}

Connect-RjRbGraph
Connect-RjRbAzAccount

$beforedate = "2021-12-06T00:00:00Z"

try {

    $appregs = Invoke-RjRbRestMethodGraph -Resource "/applications" -OdSelect "displayName,id,appId,createdDateTime,keyCredentials" -OdFilter "createdDateTime ge $beforedate"


    $AffectedAppRegs = @()
    foreach ($appreg in $appregs) {
        if ($appreg.displayName) {
            $DisplayName = $appreg.displayName
        }
        else {
            $DisplayName = $appreg.Id
        }
        $appID = $appReg.Id

        #Write-Verbose "Trying - $displayName"
        foreach ($cred in $appReg.keyCredentials) {
            if ($cred.Key.Length -gt 2000) {
                $outputBase = "$PWD\$appID"
                $outputFile = "$PWD\$appID.pfx"
                $iter = 1

                while (Test-Path $outputFile) {                    
                    $outputFile = ( -join ($outputBase, '-', ([string]$iter), '.pfx'))
                    $iter += 1
                    "`tMultiple Creds - Trying $outputFile"
                }
                [IO.File]::WriteAllBytes($outputFile, [Convert]::FromBase64String($cred.Key))
                $certResults = Get-PfxData $outputFile
                #startdate cert, displayname, appid
                $ErrorActionPreference = 'SilentlyContinue'
                if ($null -ne $certResults) {
                    Write-RjRbLog "`t$displayName - $appID - has a stored pfx credential"    
                    $AffectedAppRegs += "$displayName `t $appID" 
                }
                else {
                    Remove-Item $outputFile | Out-Null
                }
            }
        }
    }
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
    $filename = "AffectedAppRegs.csv"
    $AffectedAppRegs | ConvertTo-Csv > $filename
    Write-RjRbLog "Upload"
    Set-AzStorageBlobContent -File $fileName -Container $ContainerName -Blob $fileName -Context $context -Force | Out-Null

    $EndTime = (Get-Date).AddDays(6)
    $SASLink = New-AzStorageBlobSASToken -Permission "r" -Container $ContainerName -Context $context -Blob $fileName -FullUri -ExpiryTime $EndTime

    "## Export of Vulnerable App registrations created."
    "## Expiry of Link: $EndTime"
    $SASLink | Out-String
}
catch {
    $_
}