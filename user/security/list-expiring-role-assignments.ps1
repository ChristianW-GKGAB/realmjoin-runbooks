<#
  .SYNOPSIS
  List users, that have no recent signins.

  .DESCRIPTION
  List users, that have no recent signins.

  .NOTES
  Permissions: MS Graph
  - Organization.Read.All

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
  [ValidateScript( { Use-RJInterface -DisplayName "Days without signin" } )]
  [int] $Days = 3000,
  [ValidateScript( { Use-RJInterface -DisplayName "Include users/guests that can not sign in" } )]
  [bool] $showBlockedUsers = $true,
  # CallerName is tracked purely for auditing purposes
  [Parameter(Mandatory = $true)]
  [string] $CallerName
)

Connect-RjRbGraph

# Calculate "last sign in date"
$expiringDate = (get-date).AddDays($Days) | Get-Date -Format "yyyy-MM-dd"
$filter = "EndDateTime lt $expiringDate" + "T00:00:00Z"

Invoke-RjRbRestMethodGraph -Resource "/roleManagement/directory/roleAssignmentScheduleInstances" -OdFilter $filter
