#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branchName,
    [Parameter()][String[]] $branches,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $dryRun
)

. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Get-UpstreamBranch.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
. $PSScriptRoot/config/git/Invoke-MergeBranches.ps1
. $PSScriptRoot/config/git/Set-GitFiles.ps1
. $PSScriptRoot/config/git/Invoke-PreserveBranch.ps1

$config = Get-Configuration

Assert-CleanWorkingDirectory
Update-Git -config $config

$upstreamBranch = Get-UpstreamBranch $config -fetch

$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote -config $config)

$finalBranches = [String[]](@($branches, $parentBranches) | ForEach-Object { $_ } | Select-Object -uniq)

$addedBranches = [String[]]($finalBranches | Where-Object { $parentBranches -notcontains $_ })

if ($addedBranches.length -eq 0) {
    throw 'All branches already upstream of target branch'
}

Invoke-PreserveBranch {
    $fullBranchName = $config.remote -eq $nil ? $branchName : "$($config.remote)/$($branchName)"
    $sha = git rev-parse --verify $fullBranchName -q 2> $nil
    git checkout $sha --quiet
    Assert-CleanWorkingDirectory

    Invoke-MergeBranches $addedBranches

    $upstreamCommitish = Set-GitFiles @{ $branchName = ($finalBranches -join "`n") } -m $commitMessage -branchName $upstreamBranch -dryRun
    if ($upstreamCommitish -eq $nil -OR $commitish -eq '') {
        throw 'Failed to update upstream branch commit'
    }

    if (-not $dryRun) {
        if ($config.remote) {
            git push $config.remote --atomic "HEAD:$($branchName)" "$($upstreamCommitish):$($upstreamBranch)"
        } else {
            git branch -f $branchName HEAD
            git branch -f $upstreamBranch $upstreamCommitish
        }
    }
}
