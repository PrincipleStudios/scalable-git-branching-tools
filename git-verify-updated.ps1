#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branchName,
    [Switch] $noFetch,
    [switch] $recurse
)

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"

$config = Get-Configuration

if (-not $noFetch) {
    Update-Git
}

$noneSpecified = ($branchName -eq $nil -OR $branchName -eq '')
$branchName = $noneSpecified ? (Get-CurrentBranch) : $branchName
$fullBranchName = $noneSpecified -OR $config.remote -eq $nil ? $branchName
    : "$($config.remote)/$($branchName)"
if ($fullBranchName -eq $nil) {
    throw "No branch specified"
}
$rcCommit = git rev-parse --verify $fullBranchName
if ($LASTEXITCODE -ne 0) {
    throw "Unknown branch: $fullBranchName"
}

$parentBranches = [String[]]($recurse `
    ? (Select-UpstreamBranches $branchName -includeRemote -config $config -recurse) `
    : (Select-UpstreamBranches $branchName -includeRemote -config $config))

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
