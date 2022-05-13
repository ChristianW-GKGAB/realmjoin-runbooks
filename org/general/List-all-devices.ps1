<#
  .SYNOPSIS
  List all devices and where they are registered.

  .DESCRIPTION
  List all devices and where they are registered.

  .NOTES
  Permissions
   MS Graph (API): 
   - DeviceManagementManagedDevices.Read.All

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
    [string] $CallerName
)
Connect-RjRbGraph
$Exportdevices = @()
$Devices = [psobject]
$Devices = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices" 

foreach($Device in $Devices){
    $primaryOwner = Invoke-RjRbRestMethodGraph -Resource "/Users/$($Device.userPrincipalName)" -OdSelect "city, country, department, usageLocation"
    $Exportdevice = @()
    $Exportdevice +=$Device
    $Exportdevice | Add-Member -Name "city" -Value $primaryOwner.city -MemberType "NoteProperty"
    $Exportdevice | Add-Member -Name "country" -Value $primaryOwner.country -MemberType "NoteProperty"
    $Exportdevice | Add-Member -Name "department" -Value $primaryOwner.department -MemberType "NoteProperty"
    $Exportdevice | Add-Member -Name "usageLocation" -Value $primaryOwner.usageLocation -MemberType "NoteProperty"
    $Exportdevices += $Exportdevice
}
#zugang zu Az storage um csv zu speichern
#oder per mail attachment schicken vgl notify-changed-Conditional-Access-Policies.ps1 und notify-changed-CA-policies.ps1

$Exportdevices | ConvertTo-Csv
