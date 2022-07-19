#!/usr/bin/env pwsh

Param(
    [Parameter(Position=1, ValueFromRemainingArguments)][String[]] $ticketNames,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type
)

. $PSScriptRoot/config/Common.ps1

$ticketNames = $ticketNames | Where-Object { $_ -ne '' }
if ($ticketNames -ne $nil) {
    $ticketNames | ForEach-Object { Assert-TicketName $_ }
}
Assert-BranchType $type -optional

$type = Coalesce $type $defaultFeatureType

$typeName = Get-BranchType $type

$branchName = & $branchTypes[$typeName].build $type $ticketNames $comment
if ((& $branchTypes[$typeName].toInfo $branchName) -eq $nil) {
    throw "Invalid arguments for branch of type $typeName (tried to name it $branchName). Please verify your inputs."
}

echo $branchName
