<#
  .SYNOPSIS
  Add or remove public folder.

  .DESCRIPTION
  Add or remove public folder.

  .NOTES
  Permissions given to the Az Automation RunAs Account:
  AzureAD Roles:
  - Exchange administrator
  Office 365 Exchange Online API
  - Exchange.ManageAsApp

  .INPUTS
  RunbookCustomization: {
        "ParameterList": [
            {
                "DisplayName": "Action",
                "DisplayBefore": "MailboxName",
                "Select": {
                    "Options": [
                        {
                            "Display": "Add a Public Folder",
                            "Customization": {
                                "Default": {
                                    "AddPublicFolder": true
                                }
                            }
                        }, {
                            "Display": "Remove a Public folder",
                            "Customization": {
                                "Default": {
                                    "AddPublicFolder": false
                                },
                                "Hide": [
                                    "MailboxName"
                                ]
                            }
                        }
                    ]
                },
                "Default": "Add a Public Folder"
            },
            {
                "Name": "CallerName",
                "Hide": true
            }
        ]
    }

#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }, ExchangeOnlineManagement

param
(
    [Parameter(Mandatory = $true)] 
    [ValidateScript( { Use-RJInterface -DisplayName "Name of Public Folder" } )]
    [string] $PublicFolderName,
    [ValidateScript( { Use-RJInterface -DisplayName "PublicFolder/Mailbox"} )]
    [string] $MailboxName,
    [Parameter(Mandatory = $true)] 
    [ValidateScript( { Use-RJInterface -DisplayName "Add a Public Folder" } )]
    [bool] $AddPublicFolder,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName

)

try {
    "## Trying to connect and check for $PublicFolderName"
    Connect-RjRbExchangeOnline
    "## connected"
    #set-PublicFolder für einstellungen verwalten
    if($AddPublicFolder){
        if($MailboxName){
            New-PublicFolder -Name $PublicFolderName -Mailbox $MailboxName
        }
        else{
            New-PublicFolder -Name $PublicFolderName 
        }
        
    }else{
        Remove-PublicFolder -Identity $PublicFolderName
    }

}catch{
    $_
}