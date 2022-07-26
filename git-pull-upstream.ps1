#!/usr/bin/env pwsh

Param(
    [Switch] $noFetch
)

. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Get-CurrentBranch.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Invoke-MergeBranches.ps1

if (-not $noFetch) {
    Update-Git
}
$branchName = Get-CurrentBranch
if ($branchName -eq $nil) {
    throw 'Must have a branch checked out'
}
$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote)

Assert-CleanWorkingDirectory
Invoke-MergeBranches ($parentBranches | select -skip 1) -noAbort
# TODO: If conflicts are detected, recommend an integration branch
