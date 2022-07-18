
<#
    .SYNOPSIS
    Restore Intune App Protection Policy
    
    .DESCRIPTION
    Restore Intune App Protection Policies from JSON files per App Protection Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppProtectionPolicy function
    
    .EXAMPLE
    Invoke-IntuneRestoreAppProtectionPolicy -Path "C:\temp" -RestoreById $true
    #>
    
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

# Get all App Protection Policies
$appProtectionPolicies = Get-ChildItem -Path "$path\App Protection Policies" -File
    
foreach ($appProtectionPolicy in $appProtectionPolicies) {
    $appProtectionPolicyContent = Get-Content -LiteralPath $appProtectionPolicy.FullName -Raw
    $appProtectionPolicyDisplayName = ($appProtectionPolicyContent | ConvertFrom-Json).displayName

    # Remove properties that are not available for creating a new configuration
    $requestBodyObject = $appProtectionPolicyContent | ConvertFrom-Json
    # Set SupportsScopeTags to $false, because $true currently returns an HTTP Status 400 Bad Request error.
    if ($requestBodyObject.supportsScopeTags) {
        $requestBodyObject.supportsScopeTags = $false
    }

    $requestBodyObject.PSObject.Properties | Foreach-Object {
        if ($null -ne $_.Value) {
            if ($_.Value.GetType().Name -eq "DateTime") {
                $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
            }
        }
    }

    $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version 

    # Restore the App Protection Policy
    try {
        $null = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/managedAppPolicies" -Method Post -Body $requestBody  -ErrorAction Stop

        [PSCustomObject]@{
            "Action" = "Restore"
            "Type"   = "App Protection Policy"
            "Name"   = $appProtectionPolicyDisplayName
            "Path"   = "App Protection Policies\$($appProtectionPolicy.Name)"
        }
    }
    catch {
        Write-Verbose "$appProtectionPolicyDisplayName - Failed to restore App Protection Policy" -Verbose
        Write-Error $_ -ErrorAction Continue
    }
}