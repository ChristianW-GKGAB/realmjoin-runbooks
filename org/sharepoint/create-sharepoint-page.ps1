<#
  .SYNOPSIS
  Create a shared mailbox.

  .DESCRIPTION
  Create a shared mailbox.

  .NOTES
  Permissions given to the Az Automation RunAs Account:
  AzureAD Roles:
  - Exchange administrator
  Office 365 Exchange Online API
  - Exchange.ManageAsApp

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "CallerName": {
                "Hide": true
            }
        }
    }

#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.6.0" }

param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "SiteId" } )]
    [string] $siteId,
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "Page Name" } )]
    [string] $PageName,
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "Headline" } )]
    [string] $Headline,
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "Page Title" } )]
    [string] $PageTitle,
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "Webpart Title" } )]
    [string] $WebpartTitle,
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Use-RJInterface -DisplayName "Webpart description" } )]
    [string] $Webpartdescription,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Connect-RjRbGraph

$site = Invoke-RjRbRestMethodGraph -Resource "/sites/$siteId"
if ($site) {
    $innerHTML = @{"innerHTML" = "<p>$Headline</p>" }
    $publishingstate = @{"level" = "checkedOut"; "versionId" = "0.1" }
    $serverProcessedContent = @{"htmlStrings" = @{}; "searchablePlainTexts" = @{"title" = "" }; "imageSources" = @{}; "links" = @{"baseUrl" = $site.webUrl }; "componentDependencies" = @{"layoutComponentId" = "8ac0c53c-e8d0-4e3e-87d0-7449eb0d4027" } }
  
    $properties = @{"selectedListId" = "032e08ab-89b0-4d8f-bc10-73094233615c"; "selectedCategory" = ""; "dateRangeOption" = 0; "startDate" = ""; "endDate" = ""; "isOnSeeAllPage" = $true; "layoutId" = "FilmStrip"; "dataProviderId" = "Event"; "webId" = "0764c419-1ecc-4126-ba32-0c25ae0fffe8"; "siteId" = $siteId }

    $webpart2data = @{"title" = $WebpartTitle; "description" = $Webpartdescription; "serverProcessedContent" = $serverProcessedContent; "dataVersion" = "1.0"; "properties" = $properties }

    $webparts = @(@{"type" = "rte"; "data" = $innerHTML }, @{"type" = "d1d91016-032f-456d-98a4-721247c305e8"; "data" = $webpart2data })

    $body = @{"name" = "$PageName.aspx"; "title" = $PageTitle; "publishingState" = $publishingstate; "webParts" = $webparts }
        

    <#
$publishingstate = @{"level"= $level; "versionId" = $versionId}
$webparts = @[]
$body = @{"name" = $name ; "title" = $title; "publishingState" = $publishingstate;}
#>
    $bodyjson = $body | ConvertTo-Json -Depth 5
    $bodyjson

    Invoke-RjRbRestMethodGraph -Resource "/sites/$siteId/pages" -Body $bodyjson -Method Post -Beta
}
else {
    "## the specified siteId is invalid."
}