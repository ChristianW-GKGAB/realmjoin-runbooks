<#
    .SYNOPSIS
    Restore Intune Group Policy Configuration Assignments
    
    .DESCRIPTION
    Restore Intune Group Policy Configuration Assignments from JSON files per Group Policy Configuration from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupGroupPolicyConfigurationAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreGroupPolicyConfigurationAssignment -Path "C:\temp" -RestoreById $true
    #>
    
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $false)]
    [bool]$RestoreById = $true,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

# Get all policies with assignments
$groupPolicyConfigurations = Get-ChildItem -Path "$Path\Administrative Templates\Assignments"
foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
    $groupPolicyConfigurationAssignments = Get-Content -LiteralPath $groupPolicyConfiguration.FullName | ConvertFrom-Json
    $groupPolicyConfigurationId = ($groupPolicyConfigurationAssignments[0]).id.Split("_")[0]

    # Create the base requestBody
    $requestBody = @{
        assignments = @()
    }
        
    # Add assignments to restore to the request body
    foreach ($groupPolicyConfigurationAssignment in $groupPolicyConfigurationAssignments) {
        $requestBody.assignments += @{
            "target" = $groupPolicyConfigurationAssignment.target
        }
    }

    # Convert the PowerShell object to JSON

    # Get the Group Policy Configuration we are restoring the assignments for
    try {
        if ($restoreById) {
            $groupPolicyConfigurationObject = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/groupPolicyConfigurations/$groupPolicyConfigurationId"
        }
        else {
            $groupPolicyConfigurationObject = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/groupPolicyConfigurations" -FollowPaging | Where-Object displayName -eq "$($groupPolicyConfiguration.BaseName)"
            if (-not ($groupPolicyConfigurationObject)) {
                Write-Verbose "Error retrieving Intune Administrative Template for $($groupPolicyConfiguration.FullName). Skipping assignment restore" -Verbose
                continue
            }
        }
    }
    catch {
        Write-Verbose "Error retrieving Intune Administrative Template for $($groupPolicyConfiguration.FullName). Skipping assignment restore" -Verbose
        Write-Error $_ -ErrorAction Continue
        continue
    }

    # Restore the assignments
    try {
        $null = Invoke-RjRbRestMethodGraph -Resource "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/assign" -body $requestBody -Method Post -ErrorAction Stop
        [PSCustomObject]@{
            "Action" = "Restore"
            "Type"   = "Administrative Template Assignments"
            "Name"   = $groupPolicyConfigurationObject.displayName
            "Path"   = "Administrative Templates\Assignments\$($groupPolicyConfiguration.Name)"
        }
    }
    catch {
        Write-Verbose "$($groupPolicyConfigurationObject.displayName) - Failed to restore Administrative Template Assignment(s)" -Verbose
        Write-Error $_ -ErrorAction Continue
    }
}