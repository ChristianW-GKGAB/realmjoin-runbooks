<#
  .SYNOPSIS
  Check if  Serial Numbers are in the Autopilot System.

  .DESCRIPTION
  Check if  Serial Numbers are in the Autopilot System.

  .NOTES
  Permissions (Graph):
  - DeviceManagementServiceConfig.Read.All

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
    [ValidateScript( { Use-RJInterface -DisplayName "Serial Numbers of the Devices, separated by ','" } )]
    [Parameter(Mandatory = $true)]
    [string] $SerialNumbers,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph 

$SerialNumberobject = $SerialNumbers.Split(',')
$presentSerials = @()
$missingSerials = @()
foreach($SerialNumber in $SerialNumberobject){
$SerialNumber = $SerialNumber.TrimStart()
$autopilotdevice = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/windowsAutopilotDeviceIdentities" -OdFilter "contains(serialNumber,'$($SerialNumber)')" -ErrorAction SilentlyContinue 
if($autopilotdevice){
    $presentSerials += $autopilotdevice
}else{
    $missingSerials += $SerialNumber
}
}

"## the following are present:"
"## SerialNumber    Manufacturer    Model"
foreach ($presentSerial in $presentSerials){
    "## $($presentSerial.SerialNumber)  $($presentSerial.manufacturer)  $($presentSerial.model)"
}
"## the following are missing:"
"## SerialNumber"
foreach($missingSerial in $missingSerials){
    "## $missingSerial"
}


