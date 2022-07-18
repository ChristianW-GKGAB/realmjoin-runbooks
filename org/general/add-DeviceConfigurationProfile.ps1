<#
  .SYNOPSIS
  Import a windows device into Windows Autopilot.

  .DESCRIPTION
  Import a windows device into Windows Autopilot.

  .NOTES
  Permissions: 
  MS Graph (API):
  - DeviceManagementServiceConfig.ReadWrite.All

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
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName

)

Connect-RjRbGraph


$newPolicy = [pscustomobject]@{
    name         = "test2"
    description  = "we built this from PowerShell!"
    platforms    = "windows10"
    technologies = "mdm"
    settings     = @(
        @{
            id              = "0"
            "@odata.type"   = "#microsoft.graph.deviceManagementConfigurationSetting"
            settingInstance = @{
                "@odata.type"                    = "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance"
                settingDefinitionId              = "device_vendor_msft_policy_config_devicelock_devicepasswordenabled"
            
                choiceSettingValue               = @{
                    "@odata.type"                 = "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue"
                
                    value                         = "device_vendor_msft_policy_config_devicelock_devicepasswordenabled_0"
                    children                      = @(
                        @{
                            "@odata.type"       = "#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance"
                            settingDefinitionId = "device_vendor_msft_policy_config_devicelock_maxinactivitytimedevicelock"
                            simpleSettingValue  = @{
                                "@odata.type" = "#microsoft.graph.deviceManagementConfigurationIntegerSettingValue"
                                value         = "0"
                            }
                        }
                    )
                }
            }
        }
    )
}

Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/configurationsettings" -Method Post -Body $newPolicy -Beta
