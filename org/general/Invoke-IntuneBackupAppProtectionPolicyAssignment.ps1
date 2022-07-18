<#
    .SYNOPSIS
    Backup Intune App Protection Policy Assignments
    
    .DESCRIPTION
    Backup Intune App Protection Policy Assignments as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupAppProtectionPolicyAssignment -Path "C:\temp"
    #>
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }, Microsoft.Graph.Intune

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph
Connect-MSGraph

# Create folder if not exists
if (-not (Test-Path "$Path\App Protection Policies\Assignments")) {
    $null = New-Item -Path "$Path\App Protection Policies\Assignments" -ItemType Directory
}

# Get all assignments from all policies
$appProtectionPolicies = Get-IntuneAppProtectionPolicy | Get-MSGraphAllPages

foreach ($appProtectionPolicy in $appProtectionPolicies) {
    # If Android
    if ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.androidManagedAppProtection') {
        $assignments = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/androidManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
    }
    # Elseif iOS
    elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.iosManagedAppProtection') {
        $assignments = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/iosManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
    }
    # Elseif Windows 10 with enrollment
    elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.mdmWindowsInformationProtectionPolicy') {
        $assignments = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/mdmWindowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
    }
    # Elseif Windows 10 without enrollment
    elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.windowsInformationProtectionPolicy') {
        $assignments = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/windowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
    }
    else {
        # Not supported App Protection Policy
        continue
    }

    $fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\Assignments\$($appProtectionPolicy.id) - $fileName.json"

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "App Protection Policy Assignments"
        "Name"   = $appProtectionPolicy.displayName
        "Path"   = "App Protection Policies\Assignments\$fileName.json"
    }
}