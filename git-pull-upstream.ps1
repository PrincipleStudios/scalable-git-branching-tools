#!/usr/bin/env pwsh

Param(
)

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1";

$config = Get-Configuration

Update-Git
$branchName = Get-CurrentBranch
if ($branchName -eq $nil) {
    throw 'Must have a branch checked out'
}
# TODO - check to see if current branch is pulled, too?
Assert-BranchPushed $branchName -m 'Please ensure changes are pushed (or reset) and try again.' -failIfNoUpstream
$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote -config $config)

Assert-CleanWorkingDirectory
$(Invoke-MergeBranches ($parentBranches) -noAbort).ThrowIfInvalid()
# TODO: If conflicts are detected, recommend an integration branch

if ($config.remote) {
    git push $config.remote "HEAD:$($branchName)"
}
