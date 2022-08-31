<#
  .SYNOPSIS
  Disable a device in AzureAD.

  .DESCRIPTION
  Disable a device in AzureAD.

  .NOTES
  Permissions (Graph):
  - Device.Read.All
  Roles (AzureAD):
  - Cloud Device Administrator

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
    [ValidateScript( { Use-RJInterface -DisplayName "Serial Number of the Device" } )]
    [Parameter(Mandatory = $true)]
    [string] $SerialNumber,
    [ValidateScript( { Use-RJInterface -DisplayName "Disable or Enable Device" } )]
    [bool] $Enable = $false,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph



$deviceIntune = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices" -OdFilter "serialNumber eq '$($SerialNumber)'"
$autopilotdevice = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/windowsAutopilotDeviceIdentities" -OdFilter "serialNumber eq '$($SerialNumber)'"

$deviceAAD = Invoke-RjRbRestMethodGraph -Resource "/devices"



if($autopilotdevice){
    "## autopilot true"
}
else{
    "## autopilot false"
}

if($deviceIntune){
    "## intune true"
    "## Devicename $($deviceIntune.deviceName)"
    "## Model $($deviceIntune.model)"
    "## Manufacturer $($deviceIntune.manufacturer)"
}
else{
    "## intune false"
}

