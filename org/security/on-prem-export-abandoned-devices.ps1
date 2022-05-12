import-module ActiveDirectory


#"Maximum Age for a Password"
[int] $Days = 30
#Delete abandoned devices
[bool] $Delete = $false
#Disable abandoned devices
[bool] $Disable = $false
#export the list of Abandoned Devices in a .csv
[bool] $exportcsv = $false
if($exportcsv){
    #csv Path
    [string] $CsvPath = 
    [string] $csvName = "AbandonedDevices" + (get-date).ToString("yyyymmdd")
}
#Excluded OU (Organisational Units) 
[array] $ExcludedOUs = "OUAllowOldPasswords","Domain Controllers"
# CallerName is tracked purely for auditing purposes
[string] $CallerName


$date = [datetime]::Today.AddDays(-$Days)

$AbandonedDevices = Get-ADComputer -Filter 'PasswordLastSet -le $date' -Properties "PasswordLastSet", "DistinguishedName" 
foreach($ExcludedOU in $ExcludedOUs){
    $AbandonedDevices = $AbandonedDevices | Where-Object {$_.DistinguishedName -notlike "*OU=$($ExcludedOU),*"}
}

if($Delete){
    $AbandonedDevices | Remove-ADComputer
}elseif($Disable){
    foreach ($AbandonedDevice in $AbandonedDevices){
        set-AdComputer -Identity $AbandonedDevice -Enabled $false
    }
}elseif($exportcsv){
    $AbandonedDevices | Export-Csv -Path "$($CsvPath)$($csvName).csv"
}else{
    $AbandonedDevices
}

