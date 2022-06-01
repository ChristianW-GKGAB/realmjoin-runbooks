<#
.SYNOPSIS
add on prem Users to a AAD Groups.

.PARAMETER AAdGroupIDs
List of Azure AD Group ids.

.PARAMETER inputFile
A file, containing a comma separated list of serial numbers (devices).

.PARAMETER MigGroupName
Name of the Group to migrate from.

#>

param(
    [string] $AAdGroupIDs = "",
    [Parameter(Mandatory = $true)]
    [string] $MigGroupName = ""
)
$AAdGroupIDs.Split(',')

Connect-MgGraph 
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet


$AADGroups = @()
foreach($AADGroupID in $AAdGroupIDs){
    $AADGroups += Get-MgGroupMember -GroupId $AADGroupID
}

$AllUsers = Get-ADUser -Properties whencreated -Filter *
$beforedate = (Get-Date).AddDays(-1)

$MigGroupMemberGUIDs = get-ADGroupMember -Identity $MigGroupName -Recursive | Select-Object -ExpandProperty ObjectGUID
$NewUsers = @()
foreach($User in $AllUsers){
    if(($User.whencreated -gt $beforedate) -or ($MigGroupMemberGUIDs.Contains($User.ObjectGUID))){
        $NewUsers += $User
    }
}
$AADUsers = @()
foreach ($NewUser in $NewUsers){
   $AADUsers += Get-MgUser -Count userCount -ConsistencyLevel eventual -Property onPremisesUserPrincipalName,Id,userPrincipalName -Filter "onPremisesUserPrincipalName eq $($NewUser.UserPrincipalName)"
}
foreach($AADGroup in $AADGroups){
    $AADGroupMembers = @()
    $AADGroupMembers += Get-MgGroupMember -Identity $AADGroup.id -Recursive | Select-Object -ExpandProperty id
    foreach($AADUser in $AADUsers){
        if(!($ADgroupMembers.contains($AADUser.id))){
            New-MgGroupMember -GroupId $AADGroup.id -DirectoryObjectId $AADUser.Id
        }
    }
    
}
