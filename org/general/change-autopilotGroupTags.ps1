<#
.SYNOPSIS
Assign an Autopilot GroupTag to a comma separated list of serial numbers (devices).

.PARAMETER serialNumberList
Comma separated list of serial numbers. Alternatively use 'inputFile'.

.PARAMETER inputFile
A file, containing a comma separated list of serial numbers (devices).

.PARAMETER groupTag
Autopilot GroupTag to assign to the devices.
  .NOTES
  Permissions
  MS Graph (API):
  - Directory.Read.All
  - Device.Read.All

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "CallerName": {
                "Hide": true
            }
        }
    }

#>

param(
    [string] $serialNumberList = "2420-9612-6985-2910-0353-1045-54,9507-1125-2110-0085-4353-7748-30",
    [string] $inputFile = "",
    [Parameter(Mandatory = $true)]
    [string] $groupTag = ""
)

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }



if ((-not $serialNumberList) -and (-not $inputFile)) {
    "Please use either '-serialNumberList' or '-inputFile' to give a list serial numbers."
    exit
}

if (-not $serialNumberList) {
    if (-not (Test-Path -Path $inputFile -PathType Container)) {
        "'$inputFile' not found."
        exit
    }
    $serialNumberList = get-content -Raw -Path $inputFile
}

# Connecting
Connect-RjRbGraph

# Get all autopilot devices (even if more than 1000)
#$autopilotDevices = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/windowsAutopilotDeviceIdentities" | Get-MSGraphAllPages

$serialnumbers = $serialNumberList.Split(',')
$requestBody = @{"groupTag" =  $groupTag}

foreach ($serialnumber in $serialnumbers) {
    Write-Output "Updating entity: $serialnumber | groupTag: $groupTag | orderIdentifier: $($autopilotDevice.orderIdentifier)"
    Invoke-RjRbRestMethodGraph -Resource "deviceManagement/windowsAutopilotDeviceIdentities/$serialnumber/UpdateDeviceProperties" -Body $requestBody 
}

# Invoke an autopilot service sync
Invoke-RjRbRestMethodGraph -Resource "deviceManagement/windowsAutopilotSettings/sync"