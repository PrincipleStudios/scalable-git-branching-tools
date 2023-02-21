#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $branchName,
    [switch] $recurse
)

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/git/Get-CurrentBranch.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1

$config = Get-Configuration

$branchName = ($branchName -eq $nil -OR $branchName -eq '') ? (Get-CurrentBranch) : $branchName
if ($branchName -eq $nil) {
    throw 'Must specify a branch'
}

$parentBranches = [String[]]($recurse `
    ? (Select-UpstreamBranches $branchName -includeRemote -config $config -recurse) `
    : (Select-UpstreamBranches $branchName -includeRemote -config $config))

$parentBranches
