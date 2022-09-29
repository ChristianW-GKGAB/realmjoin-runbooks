<#
.SYNOPSIS
add on prem Users to a AAD Groups.
#>
Start-Transcript -Path "C:\Temp\transcript-log.txt"
$PSVersionTable.PSVersion
#Install-Module microsoft.graph
[string] $MigGroupName = "usr - modern workplace"
[string] $logsFolder = "C:\Temp"
$AAdGroupIDs = @(
    "d60745cd-accf-48c4-bdfc-682bc23f62ce",
    "49e481f4-c5f8-41b5-8fc9-b7ba387a7255",
    "7cf033fc-1517-48ae-ac65-3fd94ffe85d2",
    "318b8a59-495e-4a03-a9a0-519024816f42",
    "fdea5c69-56bb-41b6-9e43-e865a0e52467",
    "c92462f4-fb0a-4846-82ef-ec4dfda299cd",
    "08963fae-0aa9-45ad-b7a0-71db0b4d1983",
    "a7066952-9634-4144-9c25-9657caf4684b",
    "9cae7660-7540-40b9-9c84-8f808b383d7f",
    "fb1dcd56-651b-4717-8794-cfad82cad65e", #Adobe
    "8779dc3c-156d-4b5a-a082-722be225487a",
    "4d8ba540-9397-43a6-ae75-916a3e07bc12",
    "d07e44ed-a92d-46a7-a1a8-8a9a3b98dd2a",
    "98eca959-271f-45c3-bf6a-f14c0ef0b14a",
    "df3cde40-592e-4dcb-b867-678e2b64f540",
    "d85e5056-fbe4-4c39-b0df-b93aba2bf863",
    "d5a571e1-151c-4f9e-bd02-9a2a05093d68",
    "1a5f0739-3fcf-4569-81f2-3cb1400ab26d",
    "0c43ba89-3ab2-4f5f-96b2-a25e8cb11e67",
    "fbc1179e-6bd3-4638-ae8b-4e0b67623278",
    "ec7d07e9-3180-42a5-9211-44012a627fa8",
    "6f7fe25e-930f-4511-b18c-58a847d7d7da",
    "4fc8157c-308e-4c7e-a780-1e1aa780cbce",
    "8c3a8c0b-32ff-4b3c-9883-d1379b108e88",
    "54520950-565d-4c78-988d-aadb32d78fef",
    "2c608566-6e81-40c9-87a0-603f0b702874")
$RemoveAADGroups = @()
$RemoveActiveDirectoryGroups = @()
#7657A27254647116F0288C514C1676C6A55BFCC2
#-Scopes "User.Read.All","Group.ReadWrite.All"
Connect-MgGraph -certificatethumbprint 7657A27254647116F0288C514C1676C6A55BFCC2 -TenantId df115e11-3b77-4541-a5de-32048dbf29c1 -ClientId e7b01b46-4996-453d-a4b5-af723e6f06ce
$beforedate = (Get-Date).AddDays(-1).Date
$AllUsersDE = Get-ADUser -Properties whencreated -Filter * -SearchBase "OU=DE,OU=FA,DC=AD,DC=ZZ"
$AllUsersLU = Get-ADUser -Properties whencreated -Filter * -SearchBase "OU=LU,OU=FA,DC=AD,DC=ZZ"
$AllUsersAU = Get-ADUser -Properties whencreated -Filter * -SearchBase "OU=AU,OU=FA,DC=AD,DC=ZZ"
$AllUsers = @()
$AllUsers += $AllUsersDE
$AllUsers += $AllUsersLU
$AllUsers += $AllUsersAU
#$AllUsers
$AADGroups = @()
foreach ($AADGroupID in $AAdGroupIDs) {
    $AADGroups += Get-MgGroup -GroupId $AADGroupID
}
$removeAADGroups = @()
foreach ($RemoveAADGroupID in $RemoveAADGroupIDs) {
    $removeAADGroups += Get-MgGroup -GroupId $RemoveAADGroupID
}
$MigGroupMemberGUIDs = Get-ADGroupMember -Identity $MigGroupName -Recursive | Select-Object -ExpandProperty ObjectGUID
$NewUsers = @()
$logs = @()
foreach ($User in $AllUsers) {
    if (($User.whencreated -gt $beforedate) -or ($MigGroupMemberGUIDs.Contains($User.ObjectGUID))) {
        $NewUsers += $User
    }
}
#$AllAADUsers = Get-MgUser -Count userCount -ConsistencyLevel eventual -Property onPremisesUserPrincipalName,Id,userPrincipalName,onPremisesSamAccountName
$AllAADUsers = Get-MgUser -All -Property onPremisesUserPrincipalName, Id, userPrincipalName, onPremisesSamAccountName
$AADUsers = @()
foreach ($NewUser in $NewUsers) {
    $AADUsers += $AllAADUsers | Where-Object { $_.OnPremisesUserPrincipalName -eq $NewUser.UserPrincipalName }
}
foreach ($AADGroup in $AADGroups) {
    $AADGroupMembers = @()
    $AADGroupMembers += Get-MgGroupMember -GroupId $AADGroup.id -All | Select-Object -ExpandProperty id
    foreach ($AADUser in $AADUsers) {
        if (!($AADgroupMembers.contains($AADUser.id))) {
            New-MgGroupMember -GroupId $AADGroup.id -DirectoryObjectId $AADUser.id
            $logs += "## added $($AADUser.UserPrincipalName) to $($AADGroup.DisplayName)"
        }
    }
}
foreach ($RemoveAADGroup in $RemoveAADGroups) {
    $RemoveAADGroupMembers = @()
    $RemoveAADGroupMembers = Get-MgGroupMember -GroupId $RemoveAAGroup.id | Select-Object -ExpandProperty id
    foreach ($AADUser in $AADUsers) {
        if ($RemoveAADGroupMembers.contains($AADUser.id)) {
            Remove-ADGroupMember -Identity $RemoveAADGroup.Name -Members $samaccount -Confirm:$false
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
$time = get-date -Format "yyyyMMddTHHmm"
$logs | Out-File "$logsFolder\logs-$time.txt"
#Delete files older than 1 month
$ext = "logs-*.txt", ".log"
Get-ChildItem $logsFolder -include $ext -Recurse -Force -ea 0 |
Where-Object { !$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
ForEach-Object {
    $_ | Remove-Item -Force
}
Disconnect-MgGraph
Stop-Transcript