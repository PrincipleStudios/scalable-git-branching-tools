#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branchName,
    [Switch] $noFetch
)

. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1

$config = Get-Configuration

if (-not $noFetch) {
    Update-Git -config $config
}

$fullBranchName = $config.remote -eq $nil ? $branchName : "$($config.remote)/$($branchName)"
$rcCommit = git rev-parse --verify $fullBranchName
if ($LASTEXITCODE -ne 0) {
    throw "Unknown branch: $fullBranchName"
}
$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote -config $config)

if ($parentBranches -eq $nil -OR $parentBranches.Length -eq 0) {
    throw "$fullBranchName has no parent branches"
}

$parentBranches | Where-Object { $_ -ne $nil } | ForEach-Object {
    $parentCommit = git rev-parse --verify $_
    if ($LASTEXITCODE -ne 0) {
        throw "Unknown branch: $_"
    }
    if ((git merge-base $parentCommit $rcCommit) -ne $parentCommit) {
        throw "Branch not up-to-date: $parentCommit"
    }
}
Write-Host "All branches up-to-date."
