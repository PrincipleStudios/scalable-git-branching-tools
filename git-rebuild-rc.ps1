#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $target,
    [Parameter()][Alias('add')][Alias('addUpstream')][Alias('upstreamBranches')][String[]] $with,
    [Parameter()][Alias('remove')][Alias('removeUpstream')][String[]] $without,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $allowOutOfDate,
    [switch] $allowNoUpstreams,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-rebuild-rc.json" -params @{
    target = $target;
    with = Expand-StringArray $with;
    without = Expand-StringArray $without;
    allowOutOfDate = [boolean]$allowOutOfDate;
    allowNoUpstreams = [boolean]$allowNoUpstreams;
    comment = $comment ?? '';
} -dryRun:$dryRun
