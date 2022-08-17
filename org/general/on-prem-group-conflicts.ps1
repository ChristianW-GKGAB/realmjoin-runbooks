<#
.SYNOPSIS
clean up members from conflicting groups
groups are given as array of ids
first group in array supercedes the others

#>

Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"

$groupArray = @()
$groupcounter = 0
$firstgroupMembers = @()
foreach($group in $GroupArray){
    if($groupcounter -eq 0){
        $firstgroupMembers = Get-MgGroupMember -GroupId $group | Select-Object -ExpandProperty id
        $groupcounter++
    }
    else{
        foreach($firstgroupMember in $firstgroupMembers){
            $RemoveAADGroupMembers = Get-MgGroupMember -GroupId $group | Select-Object -ExpandProperty id
            if($RemoveAADGroupMembers.contains($firstgroupMember)){
                Remove-MgGroupMemberByRef -GroupId $group -DirectoryObjectId $firstgroupMember
                "## removed $firstgroupMember from $group"
            }
        }
    }
}

