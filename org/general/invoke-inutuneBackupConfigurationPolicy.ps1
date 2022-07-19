<#
    .SYNOPSIS
    Backup Intune Settings Catalog Policies
    
    .DESCRIPTION
    Backup Intune Settings Catalog Policies as JSON files per Settings Catalog Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicy -Path "C:\temp"
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
if (-not (Test-Path "$Path\Settings Catalog")) {
    $null = New-Item -Path "$Path\Settings Catalog" -ItemType Directory
}

# Get all Setting Catalogs Policies
$configurationPolicies = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/configurationPolicies" -Beta -Method Get  -FollowPaging

foreach ($configurationPolicy in $configurationPolicies) {
    $configurationPolicy | Add-Member -MemberType NoteProperty -Name 'settings' -Value @() -Force
    $settings = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/configurationPolicies/$($configurationPolicy.id)/settings" -Beta -FollowPaging

    if ($settings -isnot [System.Array]) {
        $configurationPolicy.Settings = @($settings)
    }
    else {
        $configurationPolicy.Settings = $settings
    }
        
    $fileName = ($configurationPolicy.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $configurationPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Settings Catalog\$fileName.json"

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "Settings Catalog"
        "Name"   = $configurationPolicy.name
        "Path"   = "Settings Catalog\$fileName.json"
    }
}

