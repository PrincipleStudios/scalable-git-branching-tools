#!/usr/bin/env pwsh

Param(
    [Switch] $noFetch
)

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1";

if (-not $noFetch) {
    Update-Git
}
$branchName = Get-CurrentBranch
if ($branchName -eq $nil) {
    throw 'Must have a branch checked out'
}
$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote -config $config)

Assert-CleanWorkingDirectory
$(Invoke-MergeBranches ($parentBranches) -noAbort).ThrowIfInvalid()
# TODO: If conflicts are detected, recommend an integration branch
