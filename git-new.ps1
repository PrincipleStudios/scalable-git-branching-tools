#!/usr/bin/env pwsh

Param(
    [Parameter(Position=1, ValueFromRemainingArguments)][String[]] $ticketNames,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('t')][ValidateLength(0,25)][String] $type,
    [Parameter()][Alias('from')][String[]] $parentBranches,
    [Switch] $noFetch
)

. $PSScriptRoot/config/core/split-string.ps1
$ticketNames = [String[]]($ticketNames -eq $nil ? @() : (Split-String $ticketNames))
$parentBranches = [String[]]($parentBranches -eq $nil ? @() : (Split-String $parentBranches))

# TODO: allow explicit branch name specification for an "other" branch type

. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/branch-utils/Format-BranchName.ps1
. $PSScriptRoot/config/git/Get-UpstreamBranchInfoFromBranchName.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
. $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1
. $PSScriptRoot/config/git/Invoke-MergeBranches.ps1
. $PSScriptRoot/config/git/Set-UpstreamBranches.ps1

$config = Get-Configuration
if (-not $noFetch) {
    Update-Git -config $config
}

$type = Coalesce $type $defaultFeatureType
$ticketNames = $ticketNames | Where-Object { $_ -ne '' -AND $_ -ne $nil }

$branchName = Format-BranchName $type $ticketNames $comment
if ($parentBranches -ne $nil -AND $parentBranches.length -gt 0) {
    $parentBranchesNoRemote = $parentBranches
    if ($config.remote -ne $nil) {
        $parentBranches = [string[]]$parentBranches | Foreach-Object { "$($config.remote)/$_" }
    }
} else {
    $parentBranchInfos = [PSObject[]](Get-UpstreamBranchInfoFromBranchName $branchName -config $config)
    $parentBranches = [string[]]($parentBranchInfos | Foreach-Object { ConvertTo-BranchName $_ -includeRemote })
    $parentBranchesNoRemote = [string[]]($parentBranchInfos | Foreach-Object { ConvertTo-BranchName $_ })
}

if ($parentBranches.Length -eq 0) {
    throw "No parents could be determined for new branch '$branchName'."
}

Assert-CleanWorkingDirectory

Set-UpstreamBranches $branchName $parentBranchesNoRemote -m "Add branch $branchName$($comment -eq $nil -OR $comment -eq '' ? '' : " for $comment")" -config $config

Invoke-CreateBranch $branchName $parentBranches[0]
Invoke-CheckoutBranch $branchName
Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
Invoke-MergeBranches ($parentBranches | select -skip 1)
