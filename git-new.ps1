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

. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
. $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1
. $PSScriptRoot/config/git/Invoke-MergeBranches.ps1
. $PSScriptRoot/config/git/Invoke-PreserveBranch.ps1
. $PSScriptRoot/config/git/Set-GitFiles.ps1

$config = Get-Configuration
if (-not $noFetch) {
    Update-Git -config $config
}

$type = Coalesce $type $defaultFeatureType

if ($parentBranches -ne $nil -AND $parentBranches.length -gt 0) {
    $parentBranchesNoRemote = $parentBranches
    if ($config.remote -ne $nil) {
        $parentBranches = [string[]]$parentBranches | Foreach-Object { "$($config.remote)/$_" }
    }
} elseif ($config.defaultServiceLine -ne $nil) {
    $parentBranchesNoRemote = [string[]] @( $config.defaultServiceLine )
    $parentBranches = [string[]] @( $config.remote ? "$($config.remote)/$($config.defaultServiceLine)" : $config.defaultServiceLine )
}

if ($parentBranches.Length -eq 0) {
    throw "No parents could be determined for new branch '$branchName'."
}

Assert-CleanWorkingDirectory

$upstreamCommitish = Set-GitFiles @{ $branchName = ($parentBranchesNoRemote -join "`n") } -m "Add branch $branchName$($comment -eq $nil -OR $comment -eq '' ? '' : " for $comment")" -branchName $config.upstreamBranch -remote $config.remote -dryRun

Invoke-PreserveBranch {
    Invoke-CreateBranch $branchName $parentBranches[0]
    Invoke-CheckoutBranch $branchName
    Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
    Invoke-MergeBranches ($parentBranches | select -skip 1)

    if ($config.remote -ne $nil) {
        git push $config.remote --atomic "$($branchName):refs/heads/$($branchName)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)"
    } else {
        git branch -f $config.upstreamBranch $upstreamCommitish --quiet
    }
} -cleanup {
    git branch -D $branchName 2> $nil
} -onlyIfError
