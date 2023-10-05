#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"

$diagnostics = New-Diagnostics
Assert-ValidBranchName $branchName -diagnostics $diagnostics
Assert-Diagnostics $diagnostics

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/git.psm1"

Update-GitRemote

$params = @{
    branchName = $branchName;
    upstreamBranches = Expand-StringArray $upstreamBranches;
    comment = $comment ?? '';
}

$instructions = Get-Content "$PSScriptRoot/git-new.json" | ConvertFrom-Json

Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

Invoke-Script $instructions -params $params -diagnostics $diagnostics -dryRun:$dryRun
