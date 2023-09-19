#!/usr/bin/env pwsh

Param(
	[Parameter()][String] $target = ''
)

Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.psm1"

# $config = Get-Configuration

Update-GitRemote
if ($target -eq '') {
	$target = Get-CurrentBranch
}

if ($target -eq $nil) {
	throw 'Must have a branch checked out or specify one.'
}

Select-UpstreamBranchGraph $target