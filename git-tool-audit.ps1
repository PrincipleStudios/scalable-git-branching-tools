#!/usr/bin/env pwsh

Param(
	[Switch] $prune,
	[Switch] $simplify,
    [Switch] $apply
)

if (-not $prune -AND -not $simplify) {
    $prune = $true
    $simplify = $true
}

Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/audit/audit-simplify.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/audit/audit-prune.psm1"

Update-Git -prune
Write-Host 'Finished ''git fetch origin'''

$applySplat = $apply ? @('-apply') : @()

if ($simplify) {
    Invoke-SimplifyAudit -apply:$apply
}

if ($prune) {
    Invoke-PruneAudit -apply:$apply
}
