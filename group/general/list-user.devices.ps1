<#
  .SYNOPSIS
  List all devices owned by group members.

  .DESCRIPTION
  List all devices owned by group members.

  .NOTES
  Permissions: 
  MS Graph (API)
  - Group.Read.All

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
    [ValidateScript( { Use-RJInterface -Type Graph -Entity Group -DisplayName "Group" } )]
    [String] $GroupID,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)
Connect-RjRbGraph
[array] $devicelist = @{}
try{
$GroupMembers = Invoke-RjRbRestMethodGraph -Resource "/Groups/$($GroupID)/Members"
    foreach ($GroupMember in $GroupMembers){

        try {  
            $UserDevices = Invoke-RjRbRestMethodGraph -Resource "/users/$($GroupMember.id)/registeredDevices"
            if($UserDevices){
                foreach ($UserDevice in $UserDevices){
                    $devicelist += $UserDevice
                }
            }
        }
        catch {
           $_
        }
       
    }
}
catch{
    $_
}
if ($devicelist) {
    $devicelist | Format-Table -AutoSize -Property "deviceid", "DisplayName" | Out-String
} else {
    "## No devices found (or no access)."
}