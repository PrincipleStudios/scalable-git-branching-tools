#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $target,
    [switch] $recurse
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.psm1"

$config = Get-Configuration

Update-GitRemote

$noneSpecified = ($target -eq $nil -OR $target -eq '')
$target = $noneSpecified ? (Get-CurrentBranch) : $target
Assert-BranchPushed $target -m 'Please ensure changes are pushed (or reset) and try again.' -failIfNoUpstream

$fullBranchName = $noneSpecified -OR $config.remote -eq $nil ? $target
    : "$($config.remote)/$($target)"
if ($fullBranchName -eq $nil) {
    throw "No branch specified"
}
$rcCommit = git rev-parse --verify $fullBranchName
if ($LASTEXITCODE -ne 0) {
    throw "Unknown branch: $fullBranchName"
}

$parentBranches = [String[]]($recurse `
    ? (Select-UpstreamBranches $target -includeRemote -config $config -recurse) `
    : (Select-UpstreamBranches $target -includeRemote -config $config))

if ($parentBranches -eq $nil -OR $parentBranches.Length -eq 0) {
    throw "$fullBranchName has no parent branches"
}

$parentBranches | Where-Object { $_ -ne $nil } | ForEach-Object {
    $parentCommit = git rev-parse --verify $_
    if ($LASTEXITCODE -ne 0) {
        throw "Unknown branch: $_"
    }
    if ((git merge-base $parentCommit $rcCommit) -ne $parentCommit) {
        throw "Branch not up-to-date: $_"
    }
}
Write-Host "All branches up-to-date."
