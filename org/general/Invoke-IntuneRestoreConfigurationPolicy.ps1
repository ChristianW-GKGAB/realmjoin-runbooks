<#
    .SYNOPSIS
    Restore Intune Settings Catalog Policies
    
    .DESCRIPTION
    Restore Intune Settings Catalog Policies from JSON files per Settings Catalog Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupConfigurationPolicy function
    
    .EXAMPLE
    Invoke-IntuneRestoreConfigurationPolicy -Path "C:\temp"
    #>
    
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.7.0" }, Microsoft.Graph.Intune

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

# Get all Settings Catalog Policies
$configurationPolicies = Get-ChildItem -Path "$Path\Settings Catalog" -File

foreach ($configurationPolicy in $configurationPolicies) {
    $configurationPolicyContent = Get-Content -LiteralPath $configurationPolicy.FullName -Raw | ConvertFrom-Json
        
    # Remove properties that are not available for creating a new configuration
    $requestBody = $configurationPolicyContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, settingCount, creationSource 

    # Restore the Settings Catalog Policy
    try {
        Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/configurationPolicies" -Method Post -Body $requestBody -Beta -ErrorAction Stop
        [PSCustomObject]@{
            "Action" = "Restore"
            "Type"   = "Settings Catalog"
            "Name"   = $configurationPolicy.FullName
            "Path"   = "Settings Catalog\$($configurationPolicy.Name)"
        }
    }
    catch {
        Write-Verbose "$($configurationPolicy.FullName) - Failed to restore Settings Catalog Policy" -Verbose
        Write-Error $_ -ErrorAction Continue
    }
}