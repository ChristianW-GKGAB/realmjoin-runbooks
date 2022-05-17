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
    [string] $CallerName = "cloudadmin@c4a8cscilla.onmicrosoft.com"
)
Connect-RjRbGraph





#define TargetgroupIds and MigGroupId variables beforehand
#$ADGroupSamAccountNames = @()
[string] $MigGroupId = "7082a9d8-e27f-4ece-840d-32592f5b5967"
$TargetGroupIds = @("a5df3c1c-f2a1-4485-9489-57f4bf97d4c7", "77d44d2b-0dbf-44dc-95f2-56ada371cf54")
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
<#foreach($User in $AllUsers){
    if($User.createdDateTime -gt $beforedate){
        $NewUsers += $User
    }
}#>
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
