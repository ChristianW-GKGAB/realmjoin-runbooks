<#
.SYNOPSIS
clean up members from conflicting groups
groups are given as array of ids
first group in array supercedes the others

#>

Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"

$groupArray = @("7082a9d8-e27f-4ece-840d-32592f5b5967",
"0d3f2427-e496-45b5-9cd6-cca5adc4b5f5"
)
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

