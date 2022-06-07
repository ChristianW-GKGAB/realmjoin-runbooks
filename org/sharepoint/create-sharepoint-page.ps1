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

$body = @{
    "name"= "$PageName.aspx";
    "title"= "$PageTitle";
    "publishingState" = @{
        "level" = "checkedOut";
        "versionId" = "0.1"
    };
    "webParts"= @(
        @{
            "type"= "rte";
            "data"= @{
                "innerHTML"= "<p>$Headline</p>"
            }
        };
        @{
            "type"= "d1d91016-032f-456d-98a4-721247c305e8";
            "data"= @{
                "title" = $WebpartTitle;
                "description"= $Webpartdescription;
                "serverProcessedContent"= @{
                    "htmlStrings"= @{};
                    "searchablePlainTexts"= @{
                        "title"= ""
                    };
                    "imageSources"= @{};
                    "links"= @{
                        "baseUrl"= "https://www.contoso.com/sites/Engineering"
                    };
                    "componentDependencies"= @{
                        "layoutComponentId"= "8ac0c53c-e8d0-4e3e-87d0-7449eb0d4027"
                    }
                };
                "dataVersion"= "1.0";
                "properties"= @{
                    "selectedListId"= "032e08ab-89b0-4d8f-bc10-73094233615c";
                    "selectedCategory"= "";
                    "dateRangeOption"= 0;
                    "startDate"= "";
                    "endDate"= "";
                    "isOnSeeAllPage"= $false;
                    "layoutId"= "FilmStrip";
                    "dataProviderId"= "Event";
                    "webId"= "0764c419-1ecc-4126-ba32-0c25ae0fffe8";
                    "siteId"= "6b4ffc7a-cfc2-4a76-903a-1cc3686dee23"
                }
            }
        }
    )
}


<#
$publishingstate = @{"level"= $level; "versionId" = $versionId}
$webparts = @[]
$body = @{"name" = $name ; "title" = $title; "publishingState" = $publishingstate;}
#>
$body

Invoke-RjRbRestMethodGraph -Resource "/sites/$($siteId)/pages" -Body $body -Beta

