#!/usr/bin/env pwsh

Param(
    [Parameter(Position=1, ValueFromRemainingArguments)][String] $ticketNames,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type
)

. $PSScriptRoot/config/Common.ps1

$ticketNames | ForEach-Object { Validate-Ticket $_ }
Validate-FeatureType $type -optional

$type = Coalesce $type $defaultFeatureType

$branchName = Format-Branch $type $ticketNames -m $comment

echo $branchName

