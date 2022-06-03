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
    [ValidateScript( { Use-RJInterface -DisplayName "list of serialnumbers seperated by ," } )]
    [string] $serialNumberList,
    [string] $inputFile,
    [ValidateScript( { Use-RJInterface -DisplayName "new group Tag" } )]
    [Parameter(Mandatory = $true)]
    [string] $groupTag,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
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