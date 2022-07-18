<#
    .SYNOPSIS
    Backup Intune App Protection Policy
    
    .DESCRIPTION
    Backup Intune App Protection Policies as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupAppProtectionPolicy -Path "C:\temp"
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
if (-not (Test-Path "$Path\App Protection Policies")) {
    $null = New-Item -Path "$Path\App Protection Policies" -ItemType Directory
}

# Get all App Protection Policies
$appProtectionPolicies = @()
$appProtectionPolicies += Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/iosManagedAppProtections" -FollowPaging -Beta
$appProtectionPolicies += Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/androidManagedAppProtections" -FollowPaging -Beta
$appProtectionPolicies += Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/defaultManagedAppProtections" -FollowPaging -Beta
$appProtectionPolicies += Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/windowsInformationProtectionPolicies" -FollowPaging -Beta


foreach ($appProtectionPolicy in $appProtectionPolicies) {
    $fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $appProtectionPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\$fileName.json"

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "App Protection Policy"
        "Name"   = $appProtectionPolicy.displayName
        "Path"   = "App Protection Policies\$fileName.json"
    }
}

