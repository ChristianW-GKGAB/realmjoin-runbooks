<#
  .SYNOPSIS
  Exports the current set of Conditional Access policies to an Azure storage account.

  .DESCRIPTION
  Exports the current set of Conditional Access policies to an Azure storage account.

  .PARAMETER ContainerName
  Will be autogenerated if left empty

  .NOTES
  Permissions
   MS Graph (API): 
   - Policy.Read.All
   - User.SendMail
   

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
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "SenderMail" } )]
    [string] $From,
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "RecipientMail" } )]
    [string] $To,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

$Subject = "Created or modified Conditional Access Policies on " + (get-date -Format yyyy-MM-dd)
$Body = "Hi Team,
in the attachment of this Mail you find the list of Conditional Access Policies that are created or modified in the last 24 hours
  
Thanks,
O365 Automation
Note: This is an auto generated email, please do not reply to this.
"
$AttachmentName = "conditional-policy-changes-" + (get-date -Format "yyyy-MM-dd")
[string] $Modifiedpolicies = @()
$Currentdate = (Get-Date).AddDays(-1)
$AllPolicies = Invoke-RjRbRestMethodGraph -Resource "/policies/conditionalAccessPolicies"
foreach ($Policy in $AllPolicies)
    {
    	$policyModifieddate =  $Policy.modifiedDateTime
    	$policyCreationdate = $Policy.createdDateTime 
    	if (($policyModifieddate -gt $Currentdate) -or ($policyCreationdate -gt $Currentdate))
    	{
    		write-host "------There are policies updated in the last 24 hours, please refer txt file." -ForegroundColor Green
    		IF (($policyModifieddate))
    		{
    			#$Modifiedpolicies += $policy
                $Modifiedpolicies += "PolicyID:$($policy.ID) & Name:$($policy.DisplayName) & Modified date:$policyModifieddate"
    		}
    		else
    		{
    			#$Modifiedpolicies += $policy 
                $Modifiedpolicies += "PolicyID:$($policy.ID) & Name:$($policy.DisplayName) & Creation date:$policyCreationdate" 
    		}
    	}
    }

if ($Modifiedpolicies.Length -ne 0 ){
    $Modifiedpoliciesbytes = [System.Text.Encoding]::UTF8.GetBytes( $Modifiedpolicies)
    $ModifiedpoliciesEncoded = [System.Convert]::ToBase64String($Modifiedpoliciesbytes)
    
    $SenderUser = Invoke-RjRbRestMethodGraph -Resource "/users/$From"
    $Mailbody = @{}
    $innerbody =@{contentType= "Text";content = $Body}      
    $emailAddress = @{"address"=$To.ToString()}
    $Recipientlist = New-Object System.Collections.ArrayList
    $Recipientlist.Add(@{"emailAddress"=$emailAddress})
                
    $attachment = New-Object System.Collections.ArrayList
    $attachment.Add(@{"@odata.type"="#microsoft.graph.fileAttachment";"name"=$AttachmentName + ".txt";"contentType" = "text/plain";"contentBytes" = $ModifiedpoliciesEncoded}) 
    $message = @{"subject"=$Subject;"body" =$innerbody;"toRecipients" = $Recipientlist;"attachments"=$attachment}     
    $Mailbody =@{"message"=$message} 
    
    $MailbodyJson = ConvertTo-Json -InputObject $Mailbody -Depth 10
    Write-Output $MailbodyJson
    try{
    Invoke-RjRbRestMethodGraph -Resource "/users/$($SenderUser.id)/microsoft.graph.SendMail" -Body $MailbodyJson
    }
    catch{
        $_
    }
    

}
else{
    "nothing changed"
}

