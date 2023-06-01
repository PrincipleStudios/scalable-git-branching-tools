#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branchName
)

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1";
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.psm1"

$config = Get-Configuration

Update-Git
if ($branchName -eq '') {
    $branchName = Get-CurrentBranch
}
if ($branchName -eq $nil) {
    throw 'Must have a branch checked out or specify one.'
}
# TODO - check to see if current branch is pulled, too?
Assert-BranchPushed $branchName -m 'Please ensure changes are pushed (or reset) and try again.' -failIfNoUpstream
$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote -config $config)

$originalHead = Get-GitHead

Assert-CleanWorkingDirectory
Invoke-CheckoutBranch $branchName

$mergeResult = Invoke-MergeBranches ($parentBranches) -noAbort
if (-not $mergeResult.isValid) {
    Write-Warning "Encountered merge conflicts while pulling upstream for $branchName. Resolve conflicts and resume with 'git pull-upstream'. If this was a release branch, abort the merge and create an integration branch instead."
} else {
    if ($config.remote -ne $nil) {
        git push $config.remote "$($branchName):refs/heads/$($branchName)"
    }
    Restore-GitHead $originalHead
}
