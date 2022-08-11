<#
  .SYNOPSIS
  Get admin accounts without MFA enabled.

  .DESCRIPTION
  Get admin accounts without MFA enabled.

  .NOTES
  Permissions: MS Graph
  - User.Read.All
  - Directory.Read.All
  - RoleManagement.Read.All

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

#instone rollout report
#ausgabe über commandlets

 
## Get builtin AzureAD Roles
$roles = Invoke-RjRbRestMethodGraph -Resource "/roleManagement/directory/roleDefinitions" -OdFilter "isBuiltIn eq true"

if ([array]$roles.count -eq 0) {
  "## Error - No AzureAD roles found. Missing permissions?"
  throw("no roles found")
}

$NoMFAAdmins = @()

$Adminuserprincipals = @()
$roles | ForEach-Object {
  # $pimHolders = Invoke-RjRbRestMethodGraph -Resource "/roleManagement/directory/roleEligibilitySchedules" -Beta -OdFilter "roleDefinitionId eq '$($_.id)'" -ErrorAction SilentlyContinue
  $roleDefinitionId = $_.id
  $pimHolders = $allPimHolders | Where-Object { $_.roleDefinitionId -eq $roleDefinitionId }
  $roleHolders = Invoke-RjRbRestMethodGraph -Resource "/roleManagement/directory/roleAssignments" -OdFilter "roleDefinitionId eq '$roleDefinitionId'" -ErrorAction SilentlyContinue

  if ((([array]$roleHolders).count -gt 0) -or (([array]$pimHolders).count -gt 0)) {


    $roleHolders | ForEach-Object {
      $principal = Invoke-RjRbRestMethodGraph -Resource "/directoryObjects/$($_.principalId)" -ErrorAction SilentlyContinue
      if (-not $principal) {
             
      }
      else {
        if ($principal."@odata.type" -eq "#microsoft.graph.user") {
          $Adminuserprincipals += $principal
        } 

      }
    }

  }

}
foreach ($Adminuserprincipal in $Adminuserprincipals) {
  [array]$MFAData = Invoke-RjRbRestMethodGraph -Resource "/users/$($Adminuserprincipal.userPrincipalName)/authentication/methods"
  $AuthenticationMethod = @()
  foreach ($MFA in $MFAData) { 
    Switch ($MFA."@odata.type") { 
      "#microsoft.graph.passwordAuthenticationMethod" {
        $AuthMethod = 'PasswordAuthentication'
      } 
      "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
        # Microsoft Authenticator App
        $AuthMethod = 'AuthenticatorApp'
      }
      "#microsoft.graph.phoneAuthenticationMethod" {
        # Phone authentication
        $AuthMethod = 'PhoneAuthentication'
      } 
      "#microsoft.graph.fido2AuthenticationMethod" {
        # FIDO2 key
        $AuthMethod = 'Fido2'
      }  
      "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" {
        # Windows Hello
        $AuthMethod = 'WindowsHelloForBusiness'
      }                        
      "#microsoft.graph.emailAuthenticationMethod" {
        # Email Authentication
        $AuthMethod = 'EmailAuthentication'
      }               
      "microsoft.graph.temporaryAccessPassAuthenticationMethod" {
        # Temporary Access pass
        $AuthMethod = 'TemporaryAccessPass'
      }
      "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" {
        # Passwordless
        $AuthMethod = 'PasswordlessMSAuthenticator'
      }      
      "#microsoft.graph.softwareOathAuthenticationMethod" { 
        $AuthMethod = 'SoftwareOath'          
      }
     
    }
    $AuthenticationMethod += $AuthMethod
  }
  [array]$StrongMFAMethods = ("Fido2", "PhoneAuthentication", "PasswordlessMSAuthenticator", "AuthenticatorApp", "WindowsHelloForBusiness")
  $MFAStatus = "Disabled"
 

  foreach ($StrongMFAMethod in $StrongMFAMethods) {
    if ($AuthenticationMethod -contains $StrongMFAMethod) {
      $MFAStatus = "Strong"
      break
    }
  }

  if (($MFAStatus -ne "Strong") -and ($AuthenticationMethod -contains "SoftwareOath")) {
    $MFAStatus = "Weak"
  }
  if ($MFAStatus -eq "Disabled") {
    $NoMFAAdmins += $Adminuserprincipal
  }
}
if ($null -ne $NoMFAAdmins) {
  "## Admins without MFA:"
  foreach ($NoMFAAdmin in $NoMFAAdmins) {
    "## $($NoMFAAdmin.UserPrincipalName)"
  }
}

