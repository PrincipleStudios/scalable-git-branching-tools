#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $target,
    [switch] $recurse
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-verify-updated.json" -params @{
    target = ($target ? $target : (Get-CurrentBranch ?? ''));
    recurse = $recurse;
    includeRemote = $includeRemote;
} -dryRun:$dryRun
