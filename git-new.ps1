#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('from')][String[]] $parentBranches,
    [Switch] $noFetch
)

. $PSScriptRoot/config/core/split-string.ps1
$parentBranches = [String[]]($parentBranches -eq $nil ? @() : (Split-String $parentBranches))

# TODO: allow explicit branch name specification for an "other" branch type

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-RemoteTracking.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Compress-UpstreamBranches.psm1"
. $PSScriptRoot/config/git/Set-GitFiles.ps1

$config = Get-Configuration
if (-not $noFetch) {
    Update-Git
}

if ($parentBranches -ne $nil -AND $parentBranches.length -gt 0) {
    $parentBranchesNoRemote = $parentBranches
} elseif ($config.defaultServiceLine -ne $nil) {
    $parentBranchesNoRemote = [string[]] @( $config.defaultServiceLine )
}
$parentBranchesNoRemote = Compress-UpstreamBranches $parentBranchesNoRemote

if ($parentBranchesNoRemote.Length -eq 0) {
    throw "No parents could be determined for new branch '$branchName'."
}

if ($config.remote -ne $nil) {
    $parentBranches = [string[]]$parentBranchesNoRemote | Foreach-Object { "$($config.remote)/$_" }
} else {
    $parentBranches = $parentBranchesNoRemote
}

Assert-CleanWorkingDirectory

$upstreamCommitish = Set-GitFiles @{ $branchName = ($parentBranchesNoRemote -join "`n") } -m "Add branch $branchName$($comment -eq $nil -OR $comment -eq '' ? '' : " for $comment")" -branchName $config.upstreamBranch -remote $config.remote -dryRun

Invoke-PreserveBranch {
    Invoke-CreateBranch $branchName $parentBranches[0]
    Invoke-CheckoutBranch $branchName
    Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
    $(Invoke-MergeBranches ($parentBranches | Select-Object -skip 1)).ThrowIfInvalid()

    if ($config.remote -ne $nil) {
        $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
        git push $config.remote @atomicPart "$($branchName):refs/heads/$($branchName)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)"
        Set-RemoteTracking $branchName
    } else {
        git branch -f $config.upstreamBranch $upstreamCommitish --quiet
    }
} -cleanup {
    git branch -D $branchName 2> $nil
} -onlyIfError
