
    <#
    .SYNOPSIS
    Restore Intune Device Compliance Policy Assignments
    
    .DESCRIPTION
    Restore Intune Device Compliance Policy Assignments from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceCompliancePolicyAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceCompliancePolicyAssignment -Path "C:\temp" -RestoreById $true
    #>
    
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.7.0" }, Microsoft.Graph.Intune

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph
    # Get all policies with assignments
    $deviceCompliancePolicies = Get-ChildItem -Path "$Path\Device Compliance Policies\Assignments"
    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $deviceCompliancePolicyAssignments = Get-Content -LiteralPath $deviceCompliancePolicy.FullName | ConvertFrom-Json
        $deviceCompliancePolicyId = ($deviceCompliancePolicyAssignments[0]).id.Split("_")[0]

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }

        # Add assignments to restore to the request body
        foreach ($deviceCompliancePolicyAssignment in $deviceCompliancePolicyAssignments) {
            $requestBody.assignments += @{
                "target" = $deviceCompliancePolicyAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Device Compliance Policy we are restoring the assignments for
        try {
            if ($restoreById) {
                $deviceCompliancePolicyObject = Get-DeviceManagement_DeviceCompliancePolicies -DeviceCompliancePolicyId $deviceCompliancePolicyId
            }
            else {
                $deviceCompliancePolicyObject = Get-DeviceManagement_DeviceCompliancePolicies | Get-MSGraphAllPages | Where-Object displayName -eq "$($deviceCompliancePolicy.BaseName)"
                if (-not ($deviceCompliancePolicyObject)) {
                    Write-Verbose "Error retrieving Intune Compliance Policy for $($deviceCompliancePolicy.FullName). Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Device Compliance Policy for $($deviceCompliancePolicy.FullName). Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-RjRbRestMethodGraph -Resource "deviceManagement/deviceCompliancePolicies/$($deviceCompliancePolicyObject.id)/assign" -Method Post -Body $requestBody -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Compliance Policy Assignments"
                "Name"   = $deviceCompliancePolicyObject.displayName
                "Path"   = "Device Compliance Policies\Assignments\$($deviceCompliancePolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$($deviceCompliancePolicyObject.displayName) - Failed to restore Device Compliance Policy Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
