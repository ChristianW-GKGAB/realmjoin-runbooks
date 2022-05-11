import-module ActiveDirectory


#define ADGroupSamAccountNames and MigGroupName variables beforehand
#$ADGroupSamAccountNames = @()
[string] $MigGroupName


$ADGroups = @()
foreach($ADGroupSamAccountName in $ADGroupSamAccountNames){
    $ADGroups += Get-ADGroup -Identity $ADGroupSamAccountName
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
foreach($ADGroup in $ADGroups){
    $ADGroupMembers = @()
    $ADGroupMembers += get-AdGroupMember -Identity $ADGroup.ObjectGUID -Recursive | Select-Object -ExpandProperty ObjectGUID
    foreach($NewUser in $NewUsers){
        if(!($ADgroupMembers.contains($NewUser.ObjectGUID))){
            Add-ADGroupMember -Identity $ADgroup.ObjectGUID -Members $NewUser.SamAccountName
        }
    }
    
}
