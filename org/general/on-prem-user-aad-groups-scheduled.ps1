<#
.SYNOPSIS
add on prem Users to a AAD Groups.
remove on prem Users from AAD Groups.
remove on prem Users from AD Groups

#>


[string] $MigGroupName = ""
$AAdGroupIDs = @()
$RemoveAADGroupIDs = @()
$RemoveActiveDirectoryGroups = @()
[string] $logsFolder = ""

Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"

$beforedate = (Get-Date).AddDays(-1)

$AllUsers = Get-ADUser -Properties whencreated -Filter *

$AADGroups = @()
foreach ($AADGroupID in $AAdGroupIDs) {
    $AADGroups += Get-MgGroup -GroupId $AADGroupID
}
$removeAADGroups = @()
foreach ($RemoveAADGroupID in $RemoveAADGroupIDs) {
    $removeAADGroups += Get-MgGroup -GroupId $RemoveAADGroupID
}

$MigGroupMemberGUIDs = get-ADGroupMember -Identity $MigGroupName -Recursive | Select-Object -ExpandProperty ObjectGUID
$NewUsers = @()
$logs = @()
foreach ($User in $AllUsers) {
    if (($User.whencreated -gt $beforedate) -or ($MigGroupMemberGUIDs.Contains($User.ObjectGUID))) {
        $NewUsers += $User
    }
}
$AllAADUsers = Get-MgUser -Count userCount -ConsistencyLevel eventual -Property onPremisesUserPrincipalName, Id, userPrincipalName
$AADUsers = @()
foreach ($NewUser in $NewUsers) {
    $AADUsers += $AllAADUsers | Where-Object { $_.OnPremisesUserPrincipalName -eq $NewUser.UserPrincipalName }
}

foreach ($AADGroup in $AADGroups) {
    
    $AADGroupMembers = @()
    $AADGroupMembers += Get-MgGroupMember -GroupId $AADGroup.id | Select-Object -ExpandProperty id

    foreach ($AADUser in $AADUsers) {
        if (!($AADgroupMembers.contains($AADUser.id))) {
            New-MgGroupMember -GroupId $AADGroup.id -DirectoryObjectId $AADUser.id
            $logs += "## added $($AADUser.UserPrincipalName) to $($AADGroup.DisplayName)"
        }
    }
    
}
foreach ($RemoveAADGroup in $RemoveAADGroups) {
    $RemoveAADGroupMembers = @()
    $RemoveAADGroupMembers = Get-MgGroupMember -GroupId $RemoveAADGroup.id | Select-Object -ExpandProperty id
    foreach ($AADUser in $AADUsers) {
        if ($RemoveAADGroupMembers.contains($AADUser.id)) {
            Remove-MgGroupMemberByRef -GroupId $RemoveAADGroup.id -DirectoryObjectId $AADUser.id
            $logs += "## removed $($AADUser.UserPrincipalName) from $($RemoveAADGroup.DisplayName)"
        }
    }
}
foreach ($RemoveActiveDirectoryGroup in $RemoveActiveDirectoryGroups) {
    $RemoveActiveDirectoryGroupMembers = @()
    $RemoveActiveDirectoryGroupMembers = Get-ADGroupMember -Identity $RemoveActiveDirectoryGroup | Select-Object -ExpandProperty SamAccountName
    foreach ($AADUser in $AADUsers) {
        if($RemoveActiveDirectoryGroupMembers.contains($AADUser.onPremisesSamAccountName)){
        Remove-ADGroupMember -Identity $RemoveActiveDirectoryGroup -Members $AADUser.onPremisesSamAccountName -Confirm:$false
        $logs += "## removed $($AADUser.UserPrincipalName) from $RemoveActiveDirectoryGroup"
        }
    }
}
$time = get-date -Format "yyyyMMddTHH"
$logs | Out-File "$logsFolder\logs-$time.txt"


#Delete files older than 1 month
Get-ChildItem $logsFolder -Recurse -Force -ea 0 |
Where-Object { !$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
ForEach-Object {
    $_ | Remove-Item -Force
}
