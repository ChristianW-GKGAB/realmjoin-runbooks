<#
  .SYNOPSIS
  List Azure AD role assignments that will expire before a given number of days.

  .DESCRIPTION
  List Azure AD role assignments that will expire before a given number of days.

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
  [ValidateScript( { Use-RJInterface -DisplayName "MAximum days before expiry" } )]
  [int] $Days = 30,
  # CallerName is tracked purely for auditing purposes
  [Parameter(Mandatory = $true)]
  [string] $CallerName
)

Connect-RjRbGraph

# Calculate "last sign in date"
$expiringDate = (get-date).AddDays($Days) | Get-Date -Format "yyyy-MM-dd"
$filter = "EndDateTime lt $expiringDate" + "T00:00:00Z"
"## shows the non role assignments that will expire before $expiringDate"
$roleassignments =  Invoke-RjRbRestMethodGraph -Resource "/roleManagement/directory/roleAssignmentScheduleInstances" -OdFilter $filter
foreach ($roleassignment in $roleassignments) {
  $roleName = (Invoke-RjRbRestMethodGraph -Resource "/roleManagement/directory/roleDefinitions/$($roleassignment.roleDefinitionId)").DisplayName
  $roleassignment | Add-Member -Name "DisplayName" -Value $roleName -MemberType "NoteProperty"
}
if ($roleassignments){
  $roleassignments
}else {
  "## no role assignments will expire in the next $Days Days"
}
