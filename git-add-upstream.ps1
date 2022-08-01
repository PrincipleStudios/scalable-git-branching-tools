#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branch,
    [Parameter()][String[]] $tickets,
    [Parameter()][String[]] $branches,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage
)

. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1

$config = Get-Configuration

Assert-CleanWorkingDirectory

$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote)

$branches = [String[]](@($branches, $parentBranches) | ForEach-Object { $_ } | Select-Object -uniq)

# TODO
