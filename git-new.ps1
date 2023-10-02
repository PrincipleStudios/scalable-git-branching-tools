#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
$upstreamBranches = Expand-StringArray $upstreamBranches

$diagnostics = New-Diagnostics
Assert-ValidBranchName $branchName -diagnostics $diagnostics
$upstreamBranches | Assert-ValidBranchName -diagnostics $diagnostics
Assert-Diagnostics $diagnostics

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/git.psm1"

$config = Get-Configuration
Update-GitRemote
# default to service line if none provided and config has a service line
$upstreamBranches = $upstreamBranches.Count -eq 0 ? @( $config.defaultServiceLine ) : $upstreamBranches
if ($upstreamBranches.length -eq 0) {
    Add-ErrorDiagnostic $diagnostics 'At least one upstream branch must be specified or the default service line must be set'
}
$upstreamBranches = Compress-UpstreamBranches $upstreamBranches -diagnostics $diagnostics

$params = @{
    branchName = $branchName;
    upstreamBranches = $upstreamBranches;
    comment = $comment ?? '';
}

$instructions = Get-Content "$PSScriptRoot/git-new.json" | ConvertFrom-Json

Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-Script $instructions -params $params -diagnostics $diagnostics -dryRun:$dryRun
Assert-Diagnostics $diagnostics
