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
            "UserName":{
                "Hide": true
            },
            "CallerName": {
                "Hide": true
            }
        }
    }

#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -Type Graph -Entity User -DisplayName "User" } )]
    [String] $UserName,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)


Connect-RjRbGraph

$User = Invoke-RjRbRestMethodGraph -Resource "/users/$UserName"
$OwnedGroups = Invoke-RjRbRestMethodGraph -Resource "/users/$($User.id)/ownedObjects/microsoft.graph.group/"

if($OwnedGroups){
    foreach ($OwnedGroup in $OwnedGroups){
        "## User $($User.UserPrincipalName) owns Group:  $($OwnedGroup.displayName)     with id: $($OwnedGroup.id)"
    }
}