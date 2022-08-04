<#
  .SYNOPSIS
  List Room configuration.

  .DESCRIPTION
  List Room configuration.

  .NOTES
  Permissions
  MS Graph (API):
  - Place.Read.All

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

param (
    [Parameter(Mandatory = $true)] 
    [ValidateScript( { Use-RJInterface -Type Graph -Entity User -DisplayName "User/Mailbox"} )]
    [string] $MailboxName,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

$User = Invoke-RjRbRestMethodGraph -Resource "/users/$($MailboxName)"

Invoke-RjRbRestMethodGraph -Resource "/places/$($User.userPrincipalName)/microsoft.graph.room" 

