#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][Alias('upstream')][String[]] $branches,
    [Parameter()][String] $branchName,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $dryRun
)

# git doesn't pass them as separate items in the array
. $PSScriptRoot/config/core/split-string.ps1
$branches = [String[]]($branches -eq $nil ? @() : (Split-String $branches))

. $PSScriptRoot/config/core/coalesce.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.psm1"
. $PSScriptRoot/config/git/Set-GitFiles.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"

$config = Get-Configuration

$isCurrentBranch = ($branchName -eq $nil -OR $branchName -eq '')
$branchName = $isCurrentBranch ? (Get-CurrentBranch) : $branchName
if ($branchName -eq $nil) {
    throw 'Must specify a branch'
}

Assert-CleanWorkingDirectory
Update-Git

Assert-BranchPushed $branchName -m 'Please ensure changes are pushed (or reset) and try again.' -failIfNoUpstream

$parentBranches = [String[]](Select-UpstreamBranches $branchName)

$finalBranches = [String[]](@($branches, $parentBranches) | ForEach-Object { $_ } | Select-Object -uniq)

$addedBranches = [String[]]($finalBranches | Where-Object { $parentBranches -notcontains $_ })

if ($addedBranches.length -eq 0) {
    throw 'All branches already upstream of target branch'
}

$commitMessage = Coalesce $commitMessage "Adding $($branches -join ',') to $branchName"

$result = Invoke-PreserveBranch {
    $fullBranchName = $config.remote -eq $nil ? $branchName : "$($config.remote)/$($branchName)"
    $sha = git rev-parse --verify $fullBranchName -q 2> $nil
    Invoke-CheckoutBranch $sha -quiet
    Assert-CleanWorkingDirectory

    $mergeResult = Invoke-MergeBranches ($config.remote -eq $nil ? $addedBranches : ($addedBranches | ForEach-Object { "$($config.remote)/$($_)" }))
    if (-not $mergeResult.isValid) {
        Write-Host -ForegroundColor yellow "Not all branches requested could be merged automatically. Please use the following commands to add it manually to your branch and then re-run ``git add-upstream``:"
        Write-Host -ForegroundColor yellow "    git merge $($mergeResult.branch)"

        return New-ResultAfterCleanup $false
    }

    $upstreamCommitish = Set-GitFiles @{ $branchName = ($finalBranches -join "`n") } -m $commitMessage -branchName $config.upstreamBranch -remote $config.remote -dryRun
    if ($upstreamCommitish -eq $nil -OR $commitish -eq '') {
        throw 'Failed to update upstream branch commit'
    }

    if (-not $dryRun) {
        if ($config.remote) {
            $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
            git push $config.remote @atomicPart "HEAD:$($branchName)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)"
        } else {
            git branch -f $config.upstreamBranch $upstreamCommitish
        }
        git branch -f $branchName HEAD
    }
}
if ($result -eq $false) {
    exit 1
}