$Path = "C:\Projects\AzureADConnectSyncDocumenter\Report"
$filename = "AADC-SERVER01-03Aug2022_AppliedTo_AADC-SERVER01-staging-03Aug2022_AADConnectSync_report.html"
$filepath = $Path + "\" + $filename

#Add-Type -path "C:\Program Files (x86)\Microsoft.NET\Primary Interop Assemblies\Microsoft.mshtml.dll"

$HTML = New-Object -ComObject "HTMLFile"
#file is an array
$file = get-content $filepath -Raw



#Find table in the website


# This works when Office is not installed    
$src = [System.Text.Encoding]::Unicode.GetBytes($file)
$HTML.write($src)
#Get-Member -InputObject $HTML.body
$Deleted = $HTML.getElementsByClassName("Deleted")
<#$tableHeader = $HTML.AllElements | Where-Object {$_.tagname -eq 'th'}
$tableData = $HTML.AllElements | Where-Object {$_.tagname -eq 'td'}
$thead = $tableHeader.innerText[0..(($tableHeader.innerText.count/2) - 1)]



#Break table data into smaller chuck of data.
$dataResult = New-Object System.Collections.ArrayList
for ($i = 0; $i -le $tdata.count; $i+= ($header.count - 1))
{
    if ($tdata.count -eq $i)
    {
        break
    }        
    $group = $i + ($header.count - 1)
    [void]$dataResult.Add($tdata[$i..$group])
    $i++
}

#Html data into powershell table format
$finalResult = @()
foreach ($data in $dataResult)
{
    $newObject = New-Object psobject
    for ($i = 0; $i -le ($thead.count - 1); $i++) {
        $newObject | Add-Member -Name $thead[$i] -MemberType NoteProperty -value $data[$i]
    }
    $finalResult += $newObject
}
$finalResult | Format-Table -AutoSize
#>