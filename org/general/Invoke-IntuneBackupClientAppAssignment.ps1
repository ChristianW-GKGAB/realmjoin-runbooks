
<#
    .SYNOPSIS
    Backup Intune Client App Assignments
    
    .DESCRIPTION
    Backup Intune Client App  Assignments as JSON files per Client App to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientAppAssignment -Path "C:\temp"
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
if (-not (Test-Path "$Path\Client Apps\Assignments")) {
    $null = New-Item -Path "$Path\Client Apps\Assignments" -ItemType Directory
}

# Get all assignments from all policies
$clientApps = Invoke-RjRbRestMethodGraph -Resource "/deviceAppManagement/mobileApps" -OdFilter "microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true" -Beta -FollowPaging

foreach ($clientApp in $clientApps) {
    $assignments = Get-DeviceAppManagement_MobileApps_Assignments -MobileAppId $clientApp.id 
    if ($assignments) {
        $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Client Apps\Assignments\$($clientApp.id) - $fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Client App Assignments"
            "Name"   = $clientApp.displayName
            "Path"   = "Client Apps\Assignments\$fileName.json"
        }
    }
}
