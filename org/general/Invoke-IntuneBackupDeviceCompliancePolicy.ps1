<#
    .SYNOPSIS
    Backup Intune Device Compliance Policies
    
    .DESCRIPTION
    Backup Intune Device Compliance Policies as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceCompliancePolicy -Path "C:\temp"
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


# Create folder if not exists
if (-not (Test-Path "$Path\Device Compliance Policies")) {
    $null = New-Item -Path "$Path\Device Compliance Policies" -ItemType Directory
}

# Get all Device Compliance Policies
$deviceCompliancePolicies = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/deviceCompliancePolicies" -FollowPaging -Beta
    
foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
    $fileName = ($deviceCompliancePolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $deviceCompliancePolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Compliance Policies\$fileName.json"

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "Device Compliance Policy"
        "Name"   = $deviceCompliancePolicy.displayName
        "Path"   = "Device Compliance Policies\$fileName.json"
    }
}
