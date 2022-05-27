Connect-MSGraph
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet
Connect-MSGraph -Quiet

# Get all autopilot devices (even if more than 1000)
#$autopilotDevices = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/windowsAutopilotDeviceIdentities" | Get-MSGraphAllPages

$serialnumberlist = ""
$serialnumbers = $serialnumberlist.Split(',')
$groupTag = ""

foreach($serialnumber in $serialnumbers){


    $requestBody=
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