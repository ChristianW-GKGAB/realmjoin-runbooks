<#
  .SYNOPSIS
  Delete a Sharepoint page.

  .DESCRIPTION
  Delete a Sharepoint page.

  .NOTES
  Permissions given to the Az Automation RunAs Account:
  AzureAD Roles:
  - Sites.ReadWrite.All

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
    [ValidateScript( { Use-RJInterface -DisplayName "SiteId" } )]
    [string] $siteId,
    [ValidateScript( { Use-RJInterface -DisplayName "PageId" } )]
    [string] $pageId,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

Invoke-RjRbRestMethodGraph -Resource "/sites/$siteId/pages/$pageId" -Method Delete