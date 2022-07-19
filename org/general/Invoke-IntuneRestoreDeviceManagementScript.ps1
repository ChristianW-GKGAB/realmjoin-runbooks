
<#
    .SYNOPSIS
    Restore Intune Device Management Scripts
    
    .DESCRIPTION
    Restore Intune Device Management Scripts from JSON files per Device Management Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceManagementScript function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceManagementScript -Path "C:\temp" -RestoreById $true
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

# Get all device management scripts
$deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts" -File
foreach ($deviceManagementScript in $deviceManagementScripts) {
    $deviceManagementScriptContent = Get-Content -LiteralPath $deviceManagementScript.FullName -Raw
    $deviceManagementScriptDisplayName = ($deviceManagementScriptContent | ConvertFrom-Json).displayName  
        
    # Remove properties that are not available for creating a new configuration
    $requestBodyObject = $deviceManagementScriptContent | ConvertFrom-Json
    $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime 

    # Restore the device management script
    try {
        $null = Invoke-RjRbRestMethodGraph  -Resource "/deviceManagement/deviceManagementScripts" -Method Post -Body $requestBody -ErrorAction Stop
        [PSCustomObject]@{
            "Action" = "Restore"
            "Type"   = "Device Management Script"
            "Name"   = $deviceManagementScriptDisplayName
            "Path"   = "Device Management Scripts\$($deviceManagementScript.Name)"
        }
    }
    catch {
        Write-Verbose "$deviceManagementScriptDisplayName - Failed to restore Device Management Script" -Verbose
        Write-Error $_ -ErrorAction Continue
    }
}
