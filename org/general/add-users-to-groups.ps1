<#
  .SYNOPSIS
  List all devices and where they are registered.

  .DESCRIPTION
  List all devices and where they are registered.

  .NOTES
  Permissions
   MS Graph (API): 
   - DeviceManagementManagedDevices.Read.All

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "CallerName": {
                "Hide": true
            }
        }
    }

#>
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }


param(
    [Parameter(Mandatory = $true)]
    [string] $CallerName 
)
Connect-RjRbGraph

#define TargetgroupIds and MigGroupId variables beforehand
[string] $MigGroupId = ""
$TargetGroupIds = @()
$beforedate = (Get-Date).AddDays(-1) | Get-Date -Format "yyyy-MM-dd"

$AADGroups = @()
foreach ($TargetGroupId in $TargetgroupIds) {
    $AADGroups += Invoke-RjRbRestMethodGraph -Resource "/groups/$TargetGroupId" 
}

$filter = 'createdDateTime ge ' + $beforedate + 'T00:00:00Z'
$NewUsers = Invoke-RjRbRestMethodGraph -Resource "/users" -OdFilter $filter

$MigGroupMembers = Invoke-RjRbRestMethodGraph -Resource "/groups/$MigGroupId/members"
$MigrationUsers = @()
$MigrationUsers += $MigGroupMembers
$MigrationUsers += $NewUsers

foreach ($AADGroup in $AADGroups) {
    $AADGroupMembers = @()
    $AADGroupMembers += Invoke-RjRbRestMethodGraph -Resource "/groups/$($AADGroup.Id)/members" -OdSelect "Id"
    [array] $bindings = @()
    foreach ($MigrationUser in $MigrationUsers) {
        if (!($AADgroupMembers.contains($MigrationUser.id))) {
            $bindings += "https://graph.microsoft.com/v1.0/directoryObjects/$($MigrationUser.id)"
        }
    }
    $GroupJson = @{"members@odata.bind" = $bindings }
    Invoke-RjRbRestMethodGraph -Resource "/groups/$($AADGroup.Id)" -Method Patch -Body $GroupJson 
}
