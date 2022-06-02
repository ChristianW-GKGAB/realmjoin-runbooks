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
    [Parameter(Mandatory = $true)]
    [string] $AAdGroupIDs = "",
    [Parameter(Mandatory = $true)]
    [string] $MigGroupName = ""
)


Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All"

$beforedate = (Get-Date).AddDays(-1)
$AADGroupIDArray =  $AAdGroupIDs.Split(',')
$AllUsers = Get-ADUser -Properties whencreated -Filter *

$AADGroups = @()
foreach($AADGroupID in $AADGroupIDArray){
    $AADGroups += Get-MgGroup -GroupId $AADGroupID
}

$MigGroupMemberGUIDs = get-ADGroupMember -Identity $MigGroupName -Recursive | Select-Object -ExpandProperty ObjectGUID
$NewUsers = @()
foreach($User in $AllUsers){
    if(($User.whencreated -gt $beforedate) -or ($MigGroupMemberGUIDs.Contains($User.ObjectGUID))){
        $NewUsers += $User
    }
}
$AllAADUsers = Get-MgUser -Count userCount -ConsistencyLevel eventual -Property onPremisesUserPrincipalName,Id,userPrincipalName
$AADUsers = @()
foreach ($NewUser in $NewUsers){
   $AADUsers += $AllAADUsers | Where-Object {$_.OnPremisesUserPrincipalName -eq $NewUser.UserPrincipalName }
}
foreach($AADGroup in $AADGroups){
    
    $AADGroupMembers = @()
    $AADGroupMembers += Get-MgGroupMember -GroupId $AADGroup.id | Select-Object -ExpandProperty id

    foreach($AADUser in $AADUsers){
        if(!($AADgroupMembers.contains($AADUser.id))){
            New-MgGroupMember -GroupId $AADGroup.id -DirectoryObjectId $AADUser.id
            "## added $($AADUser.UserPrincipalName) to $($AADGroup.DisplayName)"
        }
    }
    
}
