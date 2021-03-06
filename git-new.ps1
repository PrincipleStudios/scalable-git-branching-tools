#!/usr/bin/env pwsh

Param(
    [Parameter(Position=1, ValueFromRemainingArguments)][String[]] $ticketNames,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type,
    [Switch] $noFetch
)

. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/branch-utils/Format-BranchName.ps1
. $PSScriptRoot/config/git/Select-ParentBranches.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
. $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1
. $PSScriptRoot/config/git/Invoke-MergeBranches.ps1

if (-not $noFetch) {
    Update-Git
}

$type = Coalesce $type $defaultFeatureType
$ticketNames = $ticketNames | Where-Object { $_ -ne '' }

$branchName = Format-BranchName $type $ticketNames $comment
$parentBranches = [String[]](Select-ParentBranches $branchName -includeRemote)

if ($parentBranches.Length -eq 0) {
    throw "No parents could be determined for new branch '$branchName'."
}

Assert-CleanWorkingDirectory
Invoke-CreateBranch $branchName $parentBranches[0]
Invoke-CheckoutBranch $branchName
Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
Invoke-MergeBranches ($parentBranches | select -skip 1)
