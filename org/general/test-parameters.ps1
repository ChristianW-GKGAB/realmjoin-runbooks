#Requires -Module @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.5.1" }

[CmdletBinding(DefaultParameterSetName = 'Path')]
param
(
    [ValidateSet("Chocolate", "Strawberry", "Vanilla")]
    [string] $TestString1,
    [string] $TestString2,
    [string] $TestString3,
    [int] $TestInt,
    [double] $TestDouble,
    [datetime] $TestDatetime,
    [bool] $TestBool,
    [switch] $TestSwitch,
    [object] $TestObject1,
    [object] $TestObject2
)

$PSBoundParameters | ConvertTo-Json

if ($TestDatetime) {
    "`$TestDatetime: $($TestDatetime.ToString("o"))"
}