#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $target,
    [switch] $recurse
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
. $PSScriptRoot/config/core/coalesce.ps1

$target = ($target -eq $nil -OR $target -eq '') ? (Get-CurrentBranch) : $target
if ($target -eq $nil) {
    throw 'Must specify a branch'
}

$parentBranches = [String[]]($recurse `
    ? (Select-UpstreamBranches $target -includeRemote -recurse) `
    : (Select-UpstreamBranches $target -includeRemote))

$parentBranches
