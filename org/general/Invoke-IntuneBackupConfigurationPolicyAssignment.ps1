<#
    .SYNOPSIS
    Backup Intune Settings Catalog Policy Assignments
    
    .DESCRIPTION
    Backup Intune Settings Catalog Policy Assignments as JSON files per Settings Catalog Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicyAssignment -Path "C:\temp"
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
if (-not (Test-Path "$Path\Settings Catalog\Assignments")) {
    $null = New-Item -Path "$Path\Settings Catalog\Assignments" -ItemType Directory
}

# Get all assignments from all policies
$configurationPolicies = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/configurationPolicies" -Beta -FollowPaging

foreach ($configurationPolicy in $configurationPolicies) {
    $assignments = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/configurationPolicies/$($configurationPolicy.id)/assignments" -FollowPaging
        
    if ($assignments) {
        $fileName = ($configurationPolicy.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Settings Catalog\Assignments\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Settings Catalog Assignments"
            "Name"   = $configurationPolicy.name
            "Path"   = "Settings Catalog\Assignments\$fileName.json"
        }
    }
}