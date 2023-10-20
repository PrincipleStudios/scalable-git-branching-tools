#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches,
    [Parameter()][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-add-upstream.json" -params @{
    target = ($target ? $target : (Get-CurrentBranch));
    upstreamBranches = Expand-StringArray $upstreamBranches;
    comment = $comment ?? '';
} -dryRun:$dryRun
