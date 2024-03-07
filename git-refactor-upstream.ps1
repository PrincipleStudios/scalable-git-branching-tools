#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $source,
    [Parameter(Mandatory)][string] $target,
    [switch] $rename,
    [switch] $remove,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-refactor-upstream.json" -params @{
    source = $source;
    target = $target;
    rename = $rename;
    remove = $remove;
} -dryRun:$dryRun
