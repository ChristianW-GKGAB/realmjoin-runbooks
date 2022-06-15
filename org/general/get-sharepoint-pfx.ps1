<#
.SYNOPSIS
search users Onedrives for certificates.

#>

param(
    [Parameter(Mandatory = $true)]
    $BaseUrl = "",
    [Parameter(Mandatory = $true)]
    $Admin = "",
    [Parameter(Mandatory = $true)]
    $csvpath = "",
    [Parameter(Mandatory = $true)]
    $destinationfolder
)

 
Function get-DownloadSPFolder($SPFolderURL, $DownloadPath)
{
    Try {
        #Get the Source SharePoint Folder
        $SPFolder = $web.GetFolder($SPFolderURL)
        Write-host $SPFolder
        $DownloadPath = Join-Path $DownloadPath $SPFolder.Name
   
        #Ensure the destination local folder exists!
        If (!(Test-Path -path $DownloadPath))
        {   
            #If it doesn't exists, Create
            New-Item $DownloadPath -type directory
        }
     
        #Loop through each file in the folder and download it to Destination
        ForEach ($File in $SPFolder.Files)
        {
            #Download the file
            $Data = $File.OpenBinary()
            $FilePath= Join-Path $DownloadPath $File.Name
            [System.IO.File]::WriteAllBytes($FilePath, $data)
            Write-host -f Green "`tDownloaded the File:"$File.ServerRelativeURL        
        }
     
        #Process the Sub Folders & Recursively call the function
        ForEach ($SubFolder in $SPFolder.SubFolders)
        {
            
                #Call the function Recursively
                get-DownloadSPFolder $SubFolder $DownloadPath
            
        }
    }
    Catch {
        Write-host -f Red "Error Downloading Document Library:" $_.Exception.Message
    } 
}

#Setup Credentials to connect

$cred  = Get-Credential -UserName $admin -Message GlobalAdminLogin

Connect-SPOService -Url $BaseUrl -Credential $cred

$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)

 Import-Csv -LiteralPath 

#Setup the context

$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)

$Ctx.Credentials = $Credentials
 #Connect to SharePoint Online Admin Center

 $Usernames =  Import-Csv -Path $csvpath

  #Get all OneDrive for Business Site collections
 $AllOneDriveSites = Get-SPOSite -Template "SPSPERS" -Limit ALL -IncludePersonalSite $True
 $OneDriveSites = $AllOneDriveSites | Where-Object {$_.Owner -eq $Usernames}
 #Add Site Collection Admin to each OneDrive
 Foreach($Site in $OneDriveSites)
 {
     Write-Host -f Yellow "Adding Site Collection Admin to: "$Site.URL
     Set-SPOUser -Site $Site.Url -LoginName $Admin -IsSiteCollectionAdmin $True
     $FolderURL = Join-Path -Path $site.Url -ChildPath "SMIME"
     $userfolder = $site.owner.Split('@')[0]
     $Downloadpath = "$destinationfolder\$userfolder"
     get-DownloadSPFolder -SPFolderURL $FolderURL -DownloadPath $Downloadpath
     Set-SPOUser -Site $Site.Url -LoginName $Admin -IsSiteCollectionAdmin $false
     $site
 }
 Write-Host "Site Collection Admin Added to All OneDrive Sites Successfully!" -f Green

