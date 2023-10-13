#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Creates a new branch and checks it out from the specified branches

.PARAMETER branchName
    Specifies the name of the branch.

.PARAMETER comment
    Specifies a comment as part of the commit message for the upstream branch.

.PARAMETER upstreamBranches
    A comma-delimited list of branches (without the remote, if applicable). If not specified, assumes the default service line (see [tool-config](./tool-config.md).)

.PARAMETER dryRun
    If specified, only test merging, do not push the updates.
#>
Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/git.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/scripting.psm1"

$params = @{
    branchName = $branchName;
    upstreamBranches = Expand-StringArray $upstreamBranches;
    comment = $comment ?? '';
}
$scriptPath = "$PSScriptRoot/git-new.json"

$diagnostics = New-Diagnostics
# TODO: move this into a JSON task
Assert-ValidBranchName $branchName -diagnostics $diagnostics
Assert-Diagnostics $diagnostics

Update-GitRemote
$instructions = Get-Content $scriptPath | ConvertFrom-Json
Invoke-Script $instructions -params $params -diagnostics $diagnostics -dryRun:$dryRun
