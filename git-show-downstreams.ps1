#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $target
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
. $PSScriptRoot/config/core/coalesce.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"

$target = ($target -eq $nil -OR $target -eq '') ? (Get-CurrentBranch) : $target
if ($target -eq $nil) {
    throw 'Must specify a branch'
}

$upstreamMap = Get-UpstreamBranchMap;
$upstreamMap.Keys | Where-Object { $upstreamMap[$_] -contains "origin/$target" } | Select-Object -Unique