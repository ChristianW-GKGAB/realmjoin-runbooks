<#
  .SYNOPSIS
  Check if a device is deleted.

  .DESCRIPTION
  Check if a device is deleted.

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
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph 



$deviceIntune = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices" -OdFilter "serialNumber eq '$($SerialNumber)'" -ErrorAction SilentlyContinue
$autopilotdevice = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/windowsAutopilotDeviceIdentities" -OdFilter "contains(serialNumber,'$($SerialNumber)')" -ErrorAction SilentlyContinue 



#$deviceAAD = Invoke-RjRbRestMethodGraph -Resource "/devices"



if($autopilotdevice -and $deviceIntune){
    $AADdevice = Invoke-RjRbRestMethodGraph -Resource "/devices" -OdFilter "deviceId eq '$($deviceIntune.azureADDeviceId)'"
    "## Autopilot: exists"
    "## Intune: exists"
    if($AADdevice){
        "## Azure AD: exists"
    }
    else{
        "## Azure AD: does not exist"
    }
    "## Devicename: $($deviceIntune.deviceName)"
    "## Model: $($deviceIntune.model)"
    "## Manufacturer: $($deviceIntune.manufacturer)"
}
elseif (($null -eq $deviceIntune) -and $autopilotdevice) {
    $AADdevice = Invoke-RjRbRestMethodGraph -Resource "/devices" -OdFilter "deviceId eq '$($autopilotdevice.azureActiveDirectoryDeviceId)'" -ErrorAction SilentlyContinue
    "## Autopilot: exists"
    "## Intune: does not exist"
    if($AADdevice){
        "## Azure AD: exists"
    }
    else{
        "## Azure AD: does not exist"
    }
    "## Devicename: $($autopilotdevice.deviceName)"
    "## Model: $($autopilotdevice.model)"
    "## Manufacturer: $($autopilotdevice.manufacturer)"
}
elseif(($null -eq $autopilotdevice) -and $deviceIntune){
    $AADdevice = Invoke-RjRbRestMethodGraph -Resource "/devices" -OdFilter "deviceId eq '$($deviceIntune.azureADDeviceId)'" -ErrorAction SilentlyContinue
    "## Autopilot: does not exist"
    "## Intune: exists"
    if($AADdevice){
        "## Azure AD: exists"
    }
    else{
        "## Azure AD: does not exist"
    }
    "## Devicename: $($deviceIntune.deviceName)"
    "## Model: $($deviceIntune.model)"
    "## Manufacturer: $($deviceIntune.manufacturer)"
}
else{
    "## Autopilot: does not exist"
    "## Intune: does not exist"
}
