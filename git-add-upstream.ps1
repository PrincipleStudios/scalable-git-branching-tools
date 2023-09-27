#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches,
    [Parameter()][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $dryRun
)

# git doesn't pass them as separate items in the array
. $PSScriptRoot/config/core/split-string.ps1
$upstreamBranches = [String[]]($upstreamBranches -eq $nil ? @() : (Split-String $upstreamBranches))

. $PSScriptRoot/config/core/coalesce.ps1
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-RemoteTracking.psm1"

$config = Get-Configuration

$isCurrentBranch = ($target -eq $nil -OR $target -eq '')
$target = $isCurrentBranch ? (Get-CurrentBranch) : $target
if ($target -eq $nil) {
    throw 'Must specify a branch'
}

Assert-CleanWorkingDirectory
Update-GitRemote

Assert-BranchPushed $target -m 'Please ensure changes are pushed (or reset) and try again.' -failIfNoUpstream

$parentBranches = [String[]](Select-UpstreamBranches $target)

$finalBranches = [String[]](Compress-UpstreamBranches (@($upstreamBranches, $parentBranches) | ForEach-Object { $_ } | Select-Object -uniq))

$addedBranches = [String[]]($finalBranches | Where-Object { $parentBranches -notcontains $_ })

if ($addedBranches.length -eq 0) {
    throw 'All branches already upstream of target branch'
}

$commitMessage = "Add $($upstreamBranches -join ', ') to $target"
if ($comment -ne '') {
    $commitMessage = $commitMessage + "for $comment"
}

$result = Invoke-PreserveBranch {
    $fullBranchName = $config.remote -eq $nil ? $target : "$($config.remote)/$($target)"
    $sha = git rev-parse --verify $fullBranchName -q 2> $nil
    Invoke-CheckoutBranch $sha -quiet
    Assert-CleanWorkingDirectory

    $mergeResult = Invoke-MergeBranches ($config.remote -eq $nil ? $addedBranches : ($addedBranches | ForEach-Object { "$($config.remote)/$($_)" }))
    if (-not $mergeResult.isValid) {
        Write-Host -ForegroundColor yellow "Not all branches requested could be merged automatically. Please use the following commands to add it manually to your branch and then re-run ``git add-upstream``:"
        Write-Host -ForegroundColor yellow "    git merge $($mergeResult.branch)"

        return New-ResultAfterCleanup $false
    }

    $upstreamCommitish = Set-MultipleUpstreamBranches @{ $target = $finalBranches } -m $commitMessage
    if ($upstreamCommitish -eq $nil -OR $commitish -eq '') {
        throw 'Failed to update upstream branch commit'
    }

    if (-not $dryRun) {
        if ($config.remote) {
            $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
            git push $config.remote @atomicPart "HEAD:$($target)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)"
        } else {
            git branch -f $config.upstreamBranch $upstreamCommitish
        }
        git branch -f $target HEAD
        if ($config.remote) {
            Set-RemoteTracking $target
        }
    }
}
if ($result -eq $false) {
    exit 1
}