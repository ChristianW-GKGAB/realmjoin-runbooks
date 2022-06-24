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
            "DeviceID":{
                "Hide": true
            },
            "groupTag": {
                "Select": {
                    "Options": [
                        {
                            "Display": "More than 1 Owner necessary",
                            "Value": true
                        },
                        {
                            "Display": "only 1 Owner necessary",
                            "Value": false
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
    [Parameter(Mandatory = $true)]
    [string] $DeviceId,
    [ValidateScript( { Use-RJInterface -DisplayName "new group Tag" } )]
    [Parameter(Mandatory = $true)]
    [string] $groupTag,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

try {
    # Get all autopilot devices (even if more than 1000)
    $autopilotDevices = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/windowsAutopilotDeviceIdentities" 

    $serialnumbers = $serialNumberList.Split(',')
    $requestBody = @{"groupTag" = $groupTag }

    foreach ($serialnumber in $serialnumbers) {
        $autopilotDevice = $autopilotDevices | Where-Object { $_.serialNumber -eq $serialnumber }
        Write-Output "Updating entity: $serialnumber | groupTag: $groupTag | orderIdentifier: $($autopilotDevice.orderIdentifier)"
        Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/windowsAutopilotDeviceIdentities/$($autopilotDevice.id)/UpdateDeviceProperties" -Body $requestBody 
    }
}
catch {
    $_
}