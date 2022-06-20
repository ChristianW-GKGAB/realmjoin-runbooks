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

import-module Microsoft.Online.SharePoint.PowerShell
 
Function get-DownloadSPFolder() {
    param(
        [Parameter(Mandatory = $true)] [string] $SiteURL,
        [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.Folder] $SourceFolder,
        [Parameter(Mandatory = $true)] [string] $TargetFolder
    )
    Try {
        #Create Local Folder, if it doesn't exist

        $LocalFolder = $TargetFolder 
 
        If (!(Test-Path -Path $LocalFolder)) {
 
            New-Item -ItemType Directory -Path $LocalFolder | Out-Null
 
        }
 
          
 
        #Get all Files from the folder
 
        $FilesColl = $SourceFolder.Files
 
        $Ctx.Load($FilesColl)
 
        $Ctx.ExecuteQuery()
 
  
 
        #Iterate through each file and download
 
        Foreach ($File in $FilesColl)
        {
 
            $TargetFile = $LocalFolder + "\" + $File.Name
 
            #Download the fileS
 
            $FileInfo = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($Ctx, $File.ServerRelativeURL)
 
            $WriteStream = [System.IO.File]::Open($TargetFile, [System.IO.FileMode]::Create)
 
            $FileInfo.Stream.CopyTo($WriteStream)
 
            $WriteStream.Close()
 
            write-host -f Green "Downloaded File:"$TargetFile
 
        }
 
          
 
        #Process Sub Folders
 
        $SubFolders = $SourceFolder.Folders
 
        $Ctx.Load($SubFolders)
 
        $Ctx.ExecuteQuery()
 
        Foreach ($Folder in $SubFolders)
        {
 
            If ($Folder.Name -ne "Forms")
            {
 
                #Call the function recursively
 
                Download-SPOFolder -SiteURL $SiteURL -SourceFolder $Folder -TargetFolder $TargetFolder
 
            }
 
        }
 
    }
 
    Catch {
 
        write-host -f Red "Error Downloading Folder!" $_.Exception.Message
 
    }
 
}

#Setup Credentials to connect

$cred = Get-Credential -UserName $admin -Message GlobalAdminLogin

Connect-SPOService -Url $BaseUrl -Credential $cred

$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)

$FolderRelativeUrl = "/Documents/SMIME/"

#Connect to SharePoint Online Admin Center

$Usernames = Import-Csv -Path "$csvpath"

#Get all OneDrive for Business Site collections
$AllOneDriveSites = Get-SPOSite -Template "SPSPERS" -Limit ALL -IncludePersonalSite $True
foreach ($Username in $Usernames.Usernames) {
    $OneDriveSites += $AllOneDriveSites | Where-Object { $_.Owner -contains $Username }
}
#Add Site Collection Admin to each OneDrive
Foreach ($Site in $OneDriveSites) {
    Write-Host -f Yellow "Adding Site Collection Admin to: "$Site.URL
    Set-SPOUser -Site $Site.Url -LoginName $Admin -IsSiteCollectionAdmin $True
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($Site.Url)
    $Ctx.Credentials = $Credentials
    $Web = $Ctx.web
    $Ctx.Load($Web)
    $Ctx.ExecuteQuery()
    $Web.ServerRelativeUrl + $FolderRelativeUrl
    #Get the Folder

    $SourceFolder = $Web.GetFolderByServerRelativeUrl($Web.ServerRelativeUrl + $FolderRelativeUrl)

    $Ctx.Load($SourceFolder)

    $Ctx.ExecuteQuery()
    $userfolder = $Site.Owner.Split('@')[0]
    $Downloadpath = "$destinationfolder\$userfolder"
    get-DownloadSPFolder -SiteURL $Site.Url -SourceFolder $SourceFolder -TargetFolder $Downloadpath
    Set-SPOUser -Site $Site.Url -LoginName $Admin -IsSiteCollectionAdmin $false
    $site
}
Write-Host "Site Collection Admin Added to All OneDrive Sites Successfully!" -f Green