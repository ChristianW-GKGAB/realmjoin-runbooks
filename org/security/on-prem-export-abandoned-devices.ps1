import-module ActiveDirectory


#"Maximum Age for a Password"
[int] $Days = 30
#Delete abandoned devices
[bool] $Delete = $false
#Disable abandoned devices
[bool] $Disable = $false
#export the list of Abandoned Devices in a .csv
[bool] $exportcsv = $true
if($exportcsv){
    #csv Path
    [string] $CsvPath = ""
    [string] $csvName = "AbandonedDevices" + (get-date).ToString("yyyyMMddhhmm")
}
#included OU (Organisational Units
[array] $IncludedOUs = ""
#Excluded OU (Organisational Units) 
[array] $ExcludedOUs = "OUAllowOldPasswords","Domain Controllers"
#excluded Devices
[array] $ExcludedDevices = ""
# CallerName is tracked purely for auditing purposes
[string] $CallerName


$date = [datetime]::Today.AddDays(-$Days)

$AllAbandonedDevices = Get-ADComputer -Filter 'PasswordLastSet -le $date' -Properties "PasswordLastSet", "DistinguishedName" | Select-Object -Property DistinguishedName, DNSHostName, Enabled, ObjectGUID, PasswordLastSet

$AbandonedDevices = @()
if($IncludedOUs.Length -ge 1 -and $IncludedOUs[0] -ne ""){
    foreach($IncludedOU in $IncludedOUs){
       $AbandonedDevices += $AllAbandonedDevices | Where-Object {$_.DistinguishedName -like "*OU=$($includedOU),*"}
    }
}
else{
    $AbandonedDevices = $AllAbandonedDevices
}
foreach($ExcludedOU in $ExcludedOUs){
    $AbandonedDevices = $AbandonedDevices | Where-Object {$_.DistinguishedName -notlike "*OU=$($ExcludedOU),*"}
}

foreach($ExcludedDevice in $ExcludedDevices){
    $AbandonedDevices = $AbandonedDevices | Where-Object {$_.DistinguishedName -ne $ExcludedDevices}
}


if($Delete){
    $AbandonedDevices | Remove-ADComputer
}elseif($Disable){
    foreach ($AbandonedDevice in $AbandonedDevices){
        set-AdComputer -Identity $AbandonedDevice -Enabled $false
    }
}elseif($exportcsv){
    $AbandonedDevices | Export-Csv -Path "$($CsvPath)$($csvName).csv" -NoTypeInformation
    $AbandonedDevices
}else{
    $AbandonedDevices
}

