#!/usr/bin/env pwsh

Param(
    [Parameter(Position=1, ValueFromRemainingArguments)][String[]] $ticketNames,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type
)

. $PSScriptRoot/config/Common.ps1

$type = Coalesce $type $defaultFeatureType
$ticketNames = $ticketNames | Where-Object { $_ -ne '' }

$branchName = Format-BranchName $type $ticketNames $comment
$parentBranches = Select-ParentBranches $branchName

($branchName, $parentBranches) | ConvertTo-Json | Write-Host
