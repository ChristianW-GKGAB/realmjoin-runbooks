 <#
  .SYNOPSIS
  List groups wher user is Owner.

  .DESCRIPTION
  List groups wher user is Owner.

  .NOTES
  Permissions
   MS Graph (API): 
   - User.Read.All
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
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)


Connect-RjRbGraph

$Groups = Invoke-RjRbRestMethodGraph -Resource "/groups" -OdSelect "id,displayName"
$Ownerlessgroups = @()
foreach($Group in $Groups){
    $groupowners = Invoke-RjRbRestMethodGraph -Resource "/groups/$($Group.id)/owners"
    if($null -eq $groupowners.Value){
        $Ownerlessgroups += $Group
    }
}
#&$expand=owners($select=id,userPrincipalName,displayName)
"## list of groups without owners:"
$Ownerlessgroups