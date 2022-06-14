<#
.SYNOPSIS
Assign an Autopilot GroupTag to a comma separated list of serial numbers (devices).

.PARAMETER serialNumberList
Comma separated list of serial numbers. Alternatively use 'inputFile'.

.PARAMETER inputFile
A file, containing a comma separated list of serial numbers (devices).

.PARAMETER groupTag
Autopilot GroupTag to assign to the devices.

#>

param(
    [string] $serialNumberList = "",
    [string] $inputFile = "",
    [Parameter(Mandatory = $true)]
    [string] $groupTag = ""
)

Import-Module Microsoft.Graph.Intune

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
Connect-MSGraph
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet
Connect-MSGraph -Quiet

# Get all autopilot devices (even if more than 1000)
#$autopilotDevices = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/windowsAutopilotDeviceIdentities" | Get-MSGraphAllPages

$serialnumbers = $serialNumberList.Split(',')

foreach ($serialnumber in $serialnumbers) {
    $requestBody =
@"
    {
        groupTag: `"$groupTag`",
    }
"@
    Write-Output "Updating entity: $serialnumber | groupTag: $groupTag | orderIdentifier: $($autopilotDevice.orderIdentifier)"
    Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody -Url "deviceManagement/windowsAutopilotDeviceIdentities/$serialnumber/UpdateDeviceProperties" 
}

# Invoke an autopilot service sync
Invoke-MSGraphRequest -HttpMethod POST -Url "deviceManagement/windowsAutopilotSettings/sync"