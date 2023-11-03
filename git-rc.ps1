#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $target,
    [Parameter()][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $force,
    [switch] $allowOutOfDate,
    [switch] $allowNoUpstreams,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-JsonScript -scriptPath "$PSScriptRoot/git-rc.json" -params @{
    branchName = $target;
    upstreamBranches = Expand-StringArray $upstreamBranches;
    force = [boolean]$force;
    allowOutOfDate = [boolean]$allowOutOfDate;
    allowNoUpstreams = [boolean]$allowNoUpstreams;
    comment = $comment ?? '';
} -dryRun:$dryRun
