function Invoke-IntuneRestoreDeviceManagementScriptAssignment {
    <#
    .SYNOPSIS
    Restore Intune Device Management Script Assignments
    
    .DESCRIPTION
    Restore Intune Device Management Script Assignments from JSON files per Device Management Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceManagementScriptAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceManagementScriptAssignment -Path "C:\temp" -RestoreById $true
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

    # Get all policies with assignments
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts\Assignments"
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptAssignments = Get-Content -LiteralPath $deviceManagementScript.FullName | ConvertFrom-Json
        $deviceManagementScriptId = ($deviceManagementScriptAssignments[0]).id.Split(":")[0]

        # Create the base requestBody
        $requestBody = @{
            deviceManagementScriptAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceManagementScriptAssignment in $deviceManagementScriptAssignments) {
            $requestBody.deviceManagementScriptAssignments += @{
                "target" = $deviceManagementScriptAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Device Management Script we are restoring the assignments for
        try {
            if ($restoreById) {
                $deviceManagementScriptObject = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceManagementScripts/$deviceManagementScriptId"
            }
            else {
                $deviceManagementScriptObject = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceManagementScripts" | Get-MSGraphAllPages | Where-Object displayName -eq "$($deviceManagementScript.BaseName)"
                if (-not ($deviceManagementScriptObject)) {
                    Write-Verbose "Error retrieving Intune Device Management Script for $($deviceManagementScript.FullName). Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Device Management Script for $($deviceManagementScript.FullName). Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/deviceManagementScripts/$($deviceManagementScriptObject.id)/assign" -method Post -Body $requestBody -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Script Assignments"
                "Name"   = $deviceManagementScriptObject.displayName
                "Path"   = "Device Management Scripts\Assignments\$($deviceManagementScript.Name)"
            }
        }
        catch {
            Write-Verbose "$($deviceManagementScriptObject.displayName) - Failed to restore Device Management Script Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}