<#
  .SYNOPSIS
  Assign a phone number to a teams-enabled user and enable calling.
  
  .DESCRIPTION
  Assign a phone number to a teams-enabled user and enable calling. Needs specific permissions - see Runbook source!
  
  .NOTES
  Permissions: 
   The MicrosoftTeams PS module requires to use a "real user account" for some operations.
   This user will need the Azure AD roles: 
    - "Teams Administrator"
    - "Skype for Business Administrator"
   If you want to use this runbook, you will have to
   - Create an ADM-User object, e.g. "ADM-ServiceUser.TeamsAutomation"
   - Assign a password to the user
   - Set the password to never expire (or track the password changes accordingly)
   - Disable MFA for this user / make sure conditional access is not blocking the user
   - Add the following AzureAD roles permanently to the user:
     "Teams Administrator"
     "Skype for Business Administrator"
   - Create a credentials object in the Azure Automation Account you use for the RealmJoin Runbooks, call the credentials "teamsautomation".
   - Store the credentials (username and password) in "teamsautomation".
   This is not a recommended situation and will be fixed as soon as a technical solution is known. 

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "UserName": {
                "Hide": true
            },
            "CallerName": {
                "Hide": true
            },
            "TeamsCredentials": {
                "Hide": true
            }
        }
    }


#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }, @{ModuleName = "MicrosoftTeams"; ModuleVersion = "3.1.0" }

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -Type Graph -Entity User -DisplayName "User" } )]
    [String] $UserName,

    #Number which should be assigned
    [parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "Phone number to assign (E.164 Format - Example:+49123987654" } )]
    [String] $PhoneNumber,

    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams OnlineVoiceRoutingPolicy Name" } )]
    [String] $OnlineVoiceRoutingPolicy,

    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams DialPlan Name" } )]
    [String] $TenantDialPlan,

    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams CallingPolicy Name" } )]
    [String] $TeamsCallingPolicy,

    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

########################################################
##             Connect Part
##          
########################################################
# Needs a Microsoft Teams Connection First!

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Connection - Connect to Microsoft Teams (PowerShell)"

$CredAutomation = Get-AutomationPSCredential -Name $TeamsCredentials
Connect-MicrosoftTeams -Credential $CredAutomation

# Check if Teams connection is active
try {
    $Test = Get-CsTenant -ErrorAction Stop | Out-Null
}
catch {
    try {
        Start-Sleep -Seconds 5
        $Test = Get-CsTenant -ErrorAction Stop | Out-Null
    }
    catch {
        $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
        Write-Output "$TimeStamp - Teams PowerShell session could not be established. Stopping script!" 
        Exit
    }
}

########################################################
##             StatusQuo & Preflight-Check Part
##          
########################################################

# Get StatusQuo
$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Getting StatusQuo for user with ID:  $UserName"
$StatusQuo = Get-CsOnlineUser $UserName

$UPN = $StatusQuo.UserPrincipalName
$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - UPN from user: $UPN"

$CurrentLineUri = $StatusQuo.LineURI -replace("tel:","")

if ($StatusQuo.OnlineVoiceRoutingPolicy -like "") {
    $CurrentOnlineVoiceRoutingPolicy = "Global"
}else {
    $CurrentOnlineVoiceRoutingPolicy = $StatusQuo.OnlineVoiceRoutingPolicy
}

if ($StatusQuo.CallingPolicy -like "") {
    $CurrentCallingPolicy = "Global"
}else {
    $CurrentCallingPolicy = $StatusQuo.CallingPolicy
}

if ($StatusQuo.DialPlan -like "") {
    $CurrentDialPlan = "Global"
}else {
    $CurrentDialPlan = $StatusQuo.DialPlan
}

if ($StatusQuo.TenantDialPlan -like "") {
    $CurrentTenantDialPlan = "Global"
}else {
    $CurrentTenantDialPlan = $StatusQuo.TenantDialPlan
}

if (!($CurrentLineUri.ToString().StartsWith("+"))) {
    # Add prefix "+", if not there
    $CurrentLineUri = "+" + $CurrentLineUri
}

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Current LineUri: $CurrentLineUri"
Write-Output "$TimeStamp - Current OnlineVoiceRoutingPolicy: $CurrentOnlineVoiceRoutingPolicy"
Write-Output "$TimeStamp - Current CallingPolicy: $CurrentCallingPolicy"
Write-Output "$TimeStamp - Current DialPlan: $CurrentDialPlan"
Write-Output "$TimeStamp - Current TenantDialPlan: $CurrentTenantDialPlan"

Write-Output "$TimeStamp - Preflight-Check"
# Check if number is E.164
$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
if ($PhoneNumber -notmatch "^\+\d{8,15}") {
    Write-Output "$TimeStamp - Phone number needs to be in E.164 format ( '+#######...' )."
    throw "Phone number needs to be in E.164 format ( '+#######...' )."
}else {
    Write-Output "$TimeStamp - Phone number is in the correct E.164 format (Number: $PhoneNumber)."
}

$PhoneNumber = "+49123987655"

# Check if number is already assigned
$NumberCheck = "Empty"
$CleanNumber = "tel:+"+($PhoneNumber.Replace("+",""))
$NumberCheck = (Get-CsOnlineUser | Where-Object LineURI -Like "*$CleanNumber*").UserPrincipalName

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
if ($NumberCheck -notlike "") {
    Write-Output "$TimeStamp - Teams - Error: The assignment for $UPN could not be performed. $PhoneNumber is already assigned to $NumberCheck"
    throw "The assignment for could not be performed. PhoneNumber is already assigned!"
}else {
    Write-Output "$TimeStamp - Phone number is not yet assigned to a Microsoft Teams user"
}

#Check if number is a calling plan number
$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Check if LineUri is a Calling Plan number"
$CallingPlanNumber = (Get-CsOnlineTelephoneNumber -ResultSize 2147483647 -InventoryType Subscriber).ID
if ($CallingPlanNumber.Count -gt 0) {
    if ($CallingPlanNumber -contains $PhoneNumber.Replace("+","")) {
        $CallingPlanCheck = $true
        Write-Output "$TimeStamp - LineUri is a Calling Plan number"
    }else{
        $CallingPlanCheck = $false
        Write-Output "$TimeStamp - LineUri is a Direct Routing number"
    }
}else{
    Write-Output "$TimeStamp - LineUri is a Direct Routing number"
    $CallingPlanCheck = $false
}



########################################################
##             Main Part
##          
########################################################

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Set process"

Write-Output "$TimeStamp - Set $PhoneNumber to $UPN"
try {
    if ($CallingPlanCheck) {
        Set-CsPhoneNumberAssignment -Identity $UPN -PhoneNumber $PhoneNumber -PhoneNumberType CallingPlan -ErrorAction Stop
    }else {
        Set-CsPhoneNumberAssignment -Identity $UPN -PhoneNumber $PhoneNumber -PhoneNumberType DirectRouting -ErrorAction Stop
    }
}catch {
    $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
    Write-Output "$TimeStamp - Teams - Error: The assignment for $UPN could not be performed. Mostly no license is assigned to the user"
    throw "$TimeStamp - Teams - Error: The assignment for $UPN could not be performed!"
}

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
if (($OnlineVoiceRoutingPolicy -notlike "") -and ($TenantDialPlan -notlike "") -and ($TeamsCallingPolicy -notlike "")) {
    Write-Output "$TimeStamp - Grant Policies these policies to $UPN :"
}

# Set OnlineVoiceRoutingPolicy if defined
if ($OnlineVoiceRoutingPolicy -notlike "") {
    $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
    Write-Output "$TimeStamp - OnlineVoiceRoutingPolicy: $OnlineVoiceRoutingPolicy"
    try {
        Grant-CsOnlineVoiceRoutingPolicy -Identity $UPN -PolicyName $OnlineVoiceRoutingPolicy   
    }
    catch {
        $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
        Write-Output "$TimeStamp - Teams - Error: The assignment of OnlineVoiceRoutingPolicy for $UPN could not be completed!"
        throw "$TimeStamp - Teams - Error: The assignment of OnlineVoiceRoutingPolicy for $UPN could not be completed!"
    }
}

# Set TenantDialPlan if defined
if ($TenantDialPlan -notlike "") {
    $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
    Write-Output "$TimeStamp - TenantDialPlan: $TenantDialPlan"
    try {
        Grant-CsTenantDialPlan -Identity $UPN -PolicyName $TenantDialPlan  
    }
    catch {
        $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
        Write-Output "$TimeStamp - Teams - Error: The assignment of TenantDialPlan for $UPN could not be completed!"
        throw "$TimeStamp - Teams - Error: The assignment of TenantDialPlan for $UPN could not be completed!"
    }
}

# Set TeamsCallingPolicy if defined
if ($TeamsCallingPolicy -notlike "") {
    $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
    Write-Output "$TimeStamp - CallingPolicy: $TeamsCallingPolicy"
    try {
        Grant-CsTeamsCallingPolicy -Identity $UPN -PolicyName $TeamsCallingPolicy   
    }
    catch {
        $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
        Write-Output "$TimeStamp - Teams - Error: The assignment of TeamsCallingPolicy for $UPN could not be completed!"
        throw "$TimeStamp - Teams - Error: The assignment of TeamsCallingPolicy for $UPN could not be completed!"
    }
}

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Done!"

Disconnect-MicrosoftTeams -Confirm:$false | Out-Null
Get-PSSession | Remove-PSSession | Out-Null