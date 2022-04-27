<#
  .SYNOPSIS
  Create a room resource.

  .DESCRIPTION
  Create a room resource.

  .NOTES
  Permissions given to the Az Automation RunAs Account:
  

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "Select": {
                    "Options": [
                        {
                            "Display": "Export list of abandoned devices",
                            "Customization": {
                                "Default": {
                                    "Delete": false,
                                    "Disable": false
                                }
                            }
                        }, {
                            "Display": "Delete all abandoned devices",
                            "Customization": {
                                "Default": {
                                    "Delete": true
                                }
                            }
                        },
                        {
                            "Display": "Disable abandoned devices"
                            "Customization":{
                                "Default": {
                                    "Delete": false,
                                    "Disable": ture
                                }
                            }
                        }
                    ]
                },
            
            "CallerName": {
                "Hide": true
            }
        }
    }

#>
#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }, ActiveDirectory
param (
    [ValidateScript( { Use-RJInterface -DisplayName "Maximum Age for a Password" } )]
    [int] $Days = 30,
    [ValidateScript( { Use-RJInterface -DisplayName "Delete abandoned devices" } )]
    [bool] $Delete = $false,
    [ValidateScript( { Use-RJInterface -DisplayName "Disable abandoned devices" } )]
    [bool] $Disable = $false,
    [ValidateScript( { Use-RJInterface -DisplayName "Excluded OU (Organisational Units" } )]
    [String] $ExcludedOU,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

$date = [datetime]::Today.AddDays(-$Days)
$AbandonedDevices = Get-ADComputer -Filter "PasswordLastSet -le $($date)" -Properties * | Where-Object {$_.DistinguishedName -notlike "*OU=$($ExcludedOU),*"}

if($Delete){
    $AbandonedDevices | Remove-ADComputer
}elseif($Disable){
    foreach ($AbandonedDevice in $AbandonedDevices){
        set-AdComputer -Identity $AbandonedDevice.
    }
}else{
    $AbandonedDevices | Export-Csv
}

