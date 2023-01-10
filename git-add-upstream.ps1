#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][String[]] $branches,
    [Parameter()][String] $branchName,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $dryRun
)

# git doesn't pass them as separate items in the array
. $PSScriptRoot/config/core/split-string.ps1
$branches = [String[]]($branches -eq $nil ? @() : (Split-String $branches))

. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Get-UpstreamBranch.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
. $PSScriptRoot/config/git/Invoke-MergeBranches.ps1
. $PSScriptRoot/config/git/Set-GitFiles.ps1
. $PSScriptRoot/config/git/Invoke-PreserveBranch.ps1
. $PSScriptRoot/config/git/Get-CurrentBranch.ps1

$config = Get-Configuration

$isCurrentBranch = ($branchName -eq $nil -OR $branchName -eq '')
$branchName = ($branchName -eq $nil -OR $branchName -eq '') ? (Get-CurrentBranch) : $branchName
if ($branchName -eq $nil) {
    throw 'Must specify a branch'
}

Assert-CleanWorkingDirectory
Update-Git -config $config

$parentBranches = [String[]](Select-UpstreamBranches $branchName -config $config)

$finalBranches = [String[]](@($branches, $parentBranches) | ForEach-Object { $_ } | Select-Object -uniq)

$addedBranches = [String[]]($finalBranches | Where-Object { $parentBranches -notcontains $_ })

if ($addedBranches.length -eq 0) {
    throw 'All branches already upstream of target branch'
}

$commitMessage = Coalesce $commitMessage "Adding $($branches -join ',') to $branchName"

Invoke-PreserveBranch {
    $fullBranchName = $config.remote -eq $nil ? $branchName : "$($config.remote)/$($branchName)"
    $sha = git rev-parse --verify $fullBranchName -q 2> $nil
    git checkout $sha --quiet
    Assert-CleanWorkingDirectory

    Invoke-MergeBranches ($config.remote -eq $nil ? $addedBranches : ($addedBranches | ForEach-Object { "$($config.remote)/$($_)" }))

    $upstreamCommitish = Set-GitFiles @{ $branchName = ($finalBranches -join "`n") } -m $commitMessage -branchName $config.upstreamBranch -remote $config.remote -dryRun
    if ($upstreamCommitish -eq $nil -OR $commitish -eq '') {
        throw 'Failed to update upstream branch commit'
    }

    if (-not $dryRun) {
        if ($config.remote) {
            git push $config.remote $config.atomicPushFlag "HEAD:$($branchName)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)"
        } else {
            git branch -f $config.upstreamBranch $upstreamCommitish
        }
        git branch -f $branchName HEAD
    }
}
