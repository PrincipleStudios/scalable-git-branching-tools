#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branch,
    [Parameter()][String[]] $branches,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage
)

. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1

$config = Get-Configuration

Assert-CleanWorkingDirectory
Update-Git

$upstreamBranch = Get-UpstreamBranch $config -fetch

$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote)

$finalBranches = [String[]](@($branches, $parentBranches) | ForEach-Object { $_ } | Select-Object -uniq)

$addedBranches = [String[]]($finalBranches | Where-Object { $parentBranches -notcontains $_ })

if ($addedBranches.length -eq 0) {
    throw 'All branches already upstream of target branch'
}

Invoke-PreserveBranch {
    $fullBranchName = $config.remote -eq $nil ? $branch : "$($config.remote)/$($branch)"
    $sha = git rev-parse --verify $fullBranchName -q 2> $nil
    git checkout $sha --quiet
    Assert-CleanWorkingDirectory

    Invoke-MergeBranches $addedBranches

    # TODO - push or set local branch
    if ($config.remote) {
         
    }
}