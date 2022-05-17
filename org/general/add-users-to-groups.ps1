<#
  .SYNOPSIS
  Add new users and those in a Migration group to a set of groups.

  .DESCRIPTION
  Add new users and those in a Migration group to a set of groups.

  .NOTES
  Permissions
   MS Graph (API): 
   - DeviceManagementManagedDevices.Read.All
   - Groups.ReadWrite.All

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "CallerName": {
                "Hide": true
            },
            "TargetGroupIdString": {
                "Hide": true
            }
        }
    }

#>
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }


param(
    [ValidateScript( { Use-RJInterface -Type Graph -Entity Group -DisplayName "Source Group" } )]
    [string] $MigGroupId,
    [ValidateScript( { Use-RJInterface -DisplayName "Array of Ids of targetgroups separate by ','" } )]
    [string] $TargetGroupIdString,
    [ValidateScript( { Use-RJInterface -DisplayName "Array of targetgroup Names separate by ','" } )]
    [string] $TargetGroupNameString,
    [Parameter(Mandatory = $true)]
    [string] $CallerName 
)
Connect-RjRbGraph


$MigGroupId
if ($TargetGroupIdString) {
    $TargetGroupIds = @()
    $TargetGroupIds = $TargetGroupIdString.Split(',')
    $TargetGroupIds
}
else {
    $TargetGroupNames = @()
    $TargetGroupNames = $TargetGroupNameString.Split(',')
    $TargetGroupNames
}
#define TargetgroupIds and MigGroupId variables beforehand
#[string] $MigGroupId = ""
#$TargetGroupIds = @()
$beforedate = (Get-Date).AddDays(-1) | Get-Date -Format "yyyy-MM-dd"
try {
    $AADGroups = @()
    if ($TargetGroupIds) {
        foreach ($TargetGroupId in $TargetgroupIds) {
            $AADGroups += Invoke-RjRbRestMethodGraph -Resource "/groups/$TargetGroupId" 
        }
    }
    else {
        foreach ($TargetGroupName in $TargetGroupNames) {
            $AADGroups += Invoke-RjRbRestMethodGraph -Resource "/groups" -OdFilter "displayName eq '$TargetGroupName'"
        }
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
        "## added Users to group $($AADGroup.displayName)" 
    }
}
catch {
    $_
}
