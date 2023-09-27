#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $base,
	[Parameter()][String] $mergeCandidate
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
. $PSScriptRoot/config/core/coalesce.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"

$base = ($base -eq $nil -OR $base -eq '') ? (Get-CurrentBranch) : $base
if ($null -eq $base) {
    throw 'Must specify a base branch'
}
if ($null -eq $mergeCandidate) {
	throw 'Must specify a merge candidate'
}

Get-ConflictingBranches -base $base -mergeCandidate $mergeCandidate