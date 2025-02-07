<#
  .SYNOPSIS
  Revokes all granted permissions to a enterprise app.

  .DESCRIPTION
   Revokes all granted permissions to a enterprise app.

  .NOTES
  Permissions
   MS Graph (API): 
   - Policy.Read.All
   Azure IaaS: Access to the given Azure Storage Account / Resource Group

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

Connect-RjRbGraph
param(
    [ValidateScript( { Use-RJInterface -Type Graph -Entity Group -DisplayName "Service Principal ID" } )]
    [String] $SerivcePricipalID,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)
$permissiongrants = Invoke-RjRbRestMethodGraph -Resource "/servicePrincipals/$($SerivcePricipalID)/oauth2PermissionGrants" 
foreach( $premissionGrant in $permissiongrants){
    Invoke-RjRbRestMethodGraph -Resource "/oauth2PermissionGrants/$($premissionGrant.Id)" -Method "Delete"
}  
