<#
    .SYNOPSIS
    Backup Intune Client Apps
    
    .DESCRIPTION
    Backup Intune Client Apps as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientApp -Path "C:\temp"
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


# Create folder if not exists
if (-not (Test-Path "$Path\Client Apps")) {
    $null = New-Item -Path "$Path\Client Apps" -ItemType Directory
}

# Get all Client Apps
$clientApps = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/mobileApps" -Odfilter "microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true" -Beta -FollowPaging

foreach ($clientApp in $clientApps) {
    $clientAppType = $clientApp.'@odata.type'.split('.')[-1]

    $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $clientAppDetails = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/mobileApps/$($clientApp.id)"
    $clientAppDetails | ConvertTo-Json | Out-File -LiteralPath "$path\Client Apps\$($clientAppType)_$($fileName).json"

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "Client App"
        "Name"   = $clientApp.displayName
        "Path"   = "Client Apps\$($clientAppType)_$($fileName).json"
    }
}