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

    [parameter(Mandatory = $false)]
    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams OnlineVoiceRoutingPolicy Name" } )]
    [String] $OnlineVoiceRoutingPolicy,

    [parameter(Mandatory = $false)]
    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams DialPlan Name" } )]
    [String] $TenantDialPlan,

    [parameter(Mandatory = $false)]
    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams CallingPolicy Name" } )]
    [String] $TeamsCallingPolicy,

    [parameter(Mandatory = $false)]
    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams Meeting Policy Name" } )]
    [String] $TeamsMeetingPolicy,

    [parameter(Mandatory = $false)]
    [ValidateScript( { Use-RJInterface -DisplayName "Microsoft Teams Meeting Broadcast Policy Name (Live Event Policy)" } )]
    [String] $TeamsMeetingBroadcastPolicy,

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

$CredAutomation = Get-AutomationPSCredential -Name 'teamsautomation'
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

if ($StatusQuo.TeamsMeetingPolicy -like "") {
    $CurrentTeamsMeetingPolicy = "Global"
}else {
    $CurrentTeamsMeetingPolicy = $StatusQuo.TeamsMeetingPolicy
}

if ($StatusQuo.TeamsMeetingBroadcastPolicy -like "") {
    $CurrentTeamsMeetingBroadcastPolicy = "Global"
}else {
    $CurrentTeamsMeetingBroadcastPolicy = $StatusQuo.TeamsMeetingBroadcastPolicy
}

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Current OnlineVoiceRoutingPolicy: $CurrentOnlineVoiceRoutingPolicy"
Write-Output "$TimeStamp - Current CallingPolicy: $CurrentCallingPolicy"
Write-Output "$TimeStamp - Current DialPlan: $CurrentDialPlan"
Write-Output "$TimeStamp - Current TenantDialPlan: $CurrentTenantDialPlan"
Write-Output "$TimeStamp - Current TeamsMeetingPolicy: $CurrentTeamsMeetingPolicy"
Write-Output "$TimeStamp - Current TeamsMeetingBroadcastPolicy (Live Event Policy): $CurrentTeamsMeetingBroadcastPolicy"


########################################################
##             Main Part
##          
########################################################

$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Set process"

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

# Set TeamsMeetingPolicy if defined
if ($TeamsMeetingPolicy -notlike "") {
    $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
    Write-Output "$TimeStamp - CallingPolicy: $TeamsMeetingPolicy"
    try {
        Grant-CsTeamsMeetingPolicy -Identity $UPN -PolicyName $TeamsMeetingPolicy   
    }
    catch {
        $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
        Write-Output "$TimeStamp - Teams - Error: The assignment of TeamsMeetingPolicy for $UPN could not be completed!"
        throw "$TimeStamp - Teams - Error: The assignment of TeamsMeetingPolicy for $UPN could not be completed!"
    }
}

# Set TeamsMeetingBroadcastPolicy if defined
if ($TeamsMeetingBroadcastPolicy -notlike "") {
    $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
    Write-Output "$TimeStamp - CallingPolicy: $TeamsMeetingBroadcastPolicy"
    try {
        Grant-CsTeamsMeetingBroadcastPolicy -Identity $UPN -PolicyName $TeamsMeetingBroadcastPolicy   
    }
    catch {
        $TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
        Write-Output "$TimeStamp - Teams - Error: The assignment of TeamsMeetingBroadcastPolicy for $UPN could not be completed!"
        throw "$TimeStamp - Teams - Error: The assignment of TeamsMeetingBroadcastPolicy for $UPN could not be completed!"
    }
}


$TimeStamp = ([datetime]::now).tostring("yyyy-MM-dd HH:mm:ss")
Write-Output "$TimeStamp - Done!"

Disconnect-MicrosoftTeams -Confirm:$false | Out-Null
Get-PSSession | Remove-PSSession | Out-Null