#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][String] $ticketName,
    [Parameter(Position=1)][String] $subTicketName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type
)

. $PSScriptRoot/config/Common.ps1

Validate-Ticket $ticketName
Validate-Ticket $subTicketName -optional
Validate-FeatureType $type -optional

$comment = Coalesce $comment ''
$type = Coalesce $type $defaultFeatureType

$branchName = Format-Branch $type @($ticketName, $subTicketName) -m $comment

echo $branchName

