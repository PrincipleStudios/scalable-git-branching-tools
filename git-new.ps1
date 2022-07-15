#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][String] $ticketName,
    [Parameter(Position=1)][String] $subTicketName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type
)

. $PSScriptRoot/config/Common.ps1

if ($ticketName -notmatch $ticketRegex) {
    throw 'The ticket name is not valid; please enter a valid ticket name.';
}
$hasSubticket = $subTicketName -ne ''
if ($hasSubticket -AND $subTicketName -notmatch $ticketRegex) {
    throw 'The sub-ticket name is not valid; please enter a valid sub-ticket name.';
}
if ($type -ne '' -AND $subTicketName -notmatch $ticketRegex) {
    throw 'The sub-ticket name is not valid; please enter a valid sub-ticket name.';
}

$comment = Coalesce $comment 'Hello, git!'
$type = Coalesce $type $defaultFeatureType

$branchName = Format-Branch $type @($ticketName, $subTicketName) -m $comment

echo $branchName

