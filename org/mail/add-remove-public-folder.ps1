<#
  .SYNOPSIS
  Turn this users mailbox into a shared mailbox.

  .DESCRIPTION
  Turn this users mailbox into a shared mailbox.

  .NOTES
  Permissions given to the Az Automation RunAs Account:
  AzureAD Roles:
  - Exchange administrator
  Office 365 Exchange Online API
  - Exchange.ManageAsApp

  .INPUTS
  RunbookCustomization: {
            "AddPublicFolder": {
                "Hide": true
            }
        },
        "ParameterList": [
            {
                "DisplayName": "Action",
                "DisplayBefore": "AutoMapping",
                "Select": {
                    "Options": [
                        {
                            "Display": "Turn mailbox into shared mailbox",
                            "Customization": {
                                "Default": {
                                    "AddPublicFolder": true
                                }
                            }
                        }, {
                            "Display": "turn shared mailbox back into regular mailbox",
                            "Customization": {
                                "Default": {
                                    "AddPublicFolder": false
                                },
                                "Hide": [
                                    "MailboxName""
                                ]
                            }
                        }
                    ]
                },
                "Default": "Turn mailbox into shared mailbox"
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
    [ValidateScript( { Use-RJInterface DisplayName "Name of Public Folder" } )]
    [string] $PublicFolderName,
    [ValidateScript( { Use-RJInterface -Type Graph -Entity User -DisplayName "User/Mailbox"} )]
    [string] $MailboxName,
    [ValidateScript( { Use-RJInterface -DisplayName "Turn mailbox back to regular mailbox" } )]
    [bool] $AddPublicFolder = $true,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName

)

try {
    "## Trying to connect and check for $UserName"
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