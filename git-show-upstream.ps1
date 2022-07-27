#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branchName
)

. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/git/Get-CurrentBranch.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1

$branchName = ($branchName -eq $nil -OR $branchName -eq '') ? (Get-CurrentBranch) : $branchName
if ($branchName -eq $nil) {
    throw 'Must specify a branch'
}

$parentBranches = [String[]](Select-UpstreamBranches $branchName -includeRemote)

$parentBranches
