<#
  .SYNOPSIS
  List groups without Owner.

  .DESCRIPTION
  List groups without Owner.

  .NOTES
  Permissions
   MS Graph (API): 
   - Group.Read.All

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "ownerminimum": {
                "Select": {
                    "Options": [
                        {
                            "Display": "More than 1 Owner necessary",
                            "Value": true
                        },
                        {
                            "Display": "only 1 Owner necessary",
                            "Value": false,
                            "Customization": {
                                "Hide": [
                                    "minimumOwnerNumber"
                                ]
                            }
                        }
                    ]
                }
            },
            "CallerName": {
                "Hide": true
            }
        }
    }

#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }

param(
    [ValidateScript( { Use-RJInterface -DisplayName "Is More than 1 Owner necessary?" } )]
    [bool] $ownerminimum,
    [ValidateScript( { Use-RJInterface -DisplayName "Minimum Owner Number" } )]
    [int] $minimumOwnerNumber,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)


Connect-RjRbGraph

$Groups = Invoke-RjRbRestMethodGraph -Resource "/groups" -OdSelect "id,displayName,groupTypes" -OdFilter "groupTypes/any(c:c eq 'Unified')"
$Ownerlessgroups = @()
if ($ownerminimum) {
    foreach ($Group in $Groups) {
        $groupowners = Invoke-RjRbRestMethodGraph -Resource "/groups/$($Group.id)/owners"
        if ($groupowners.length -lt $minimumOwnerNumber) {
            $Ownerlessgroups += $Group
        }
    }
}
else {
    foreach ($Group in $Groups) {
        $groupowners = Invoke-RjRbRestMethodGraph -Resource "/groups/$($Group.id)/owners"
        if ($null -eq $groupowners.Value) {
            $Ownerlessgroups += $Group
        }
    }
}

"## list of groups without (enough) owners:"
$Ownerlessgroups