#!/usr/bin/env pwsh

Param(
	[Parameter()][String] $target = '',
	[switch]$checkList = $false
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"

Update-GitRemote
if ($target -eq '') {
	$target = Get-CurrentBranch
}

if ($target -eq $nil) {
	throw 'Must have a branch checked out or specify one.'
}

Select-UpstreamBranchGraph $target -checkList $checkList