#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][Alias('sourceBranch')][String] $source,
    [Parameter(Mandatory)][Alias('targetBranch')][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [Parameter()][String[]] $preserve = @(),
    [switch] $cleanupOnly,
    [switch] $force,
    [switch] $noFetch,
    [switch] $quiet,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/actions.psm1"

$diagnostics = New-Diagnostics
$config = Get-Configuration
if (-not $noFetch) {
    Update-GitRemote -quiet:$quiet
}

$commonParams = @{
    diagnostics = $diagnostics
}

# Assert up-to-date
# a) if $cleanupOnly, ensure no commits are in source that are not in target
# b) otherwise, ensure no commits are in target that are not in source
if (-not $force) {
    Invoke-LocalAction @commonParams @{
        type = 'assert-updated'
        parameters = $cleanupOnly `
            ? @{ downstream = $target; upstream = $source }
            : @{ downstream = $source; upstream = $target }
    }
    Assert-Diagnostics $diagnostics
}

# $toRemove = (git show-upstream $source -recurse) without ($target, git show-upstream $target -recurse, $preserve)
$sourceUpstream = Invoke-LocalAction @commonParams @{
    type = 'get-upstream'
    parameters = @{ target = $source; recurse = $true }
}
Assert-Diagnostics $diagnostics

$targetUpstream = Invoke-LocalAction @commonParams @{
    type = 'get-upstream'
    parameters = @{ target = $target; recurse = $true }
}
Assert-Diagnostics $diagnostics

[string[]]$keep = @($target) + $targetUpstream + $preserve
[string[]]$toRemove = (@($source) + $sourceUpstream) | Where-Object { $_ -notin $keep }

# Assert all branches removed are up-to-date, unless $force is set
if (-not $force) {
    foreach ($branch in $toRemove) {
        if ($branch -eq $source) { continue }
        Invoke-LocalAction @commonParams @{
            type = 'assert-updated'
            parameters = @{ downstream = $cleanupOnly ? $target : $source; upstream = $branch }
        }
    }
    Assert-Diagnostics $diagnostics
}

# For all branches:
#    1. Replace $toRemove branches with $target
#    2. Simplify

$originalUpstreams = Invoke-LocalAction @commonParams @{
    type = 'get-all-upstreams'
    parameters= @{}
}
Assert-Diagnostics $diagnostics

$resultUpstreams = @{}
foreach ($branch in $originalUpstreams.Keys) {
    if ($branch -in $toRemove) {
        $resultUpstreams[$branch] = $null
        continue
    }
    
    if ($originalUpstreams[$branch] | Where-Object { $_ -in $toRemove }) {
        $resultUpstreams[$branch] = Invoke-LocalAction @commonParams @{
            type = 'filter-branches'
            parameters = @{
                include = @($target) + $originalUpstreams[$branch]
                exclude = $toRemove
            }
        }
        Assert-Diagnostics $diagnostics
    }
}

$keys = @() + $resultUpstreams.Keys
foreach ($branch in $keys) {
    if (-not $resultUpstreams[$branch]) { continue }
    $resultUpstreams[$branch] = Invoke-LocalAction @commonParams @{
        type = 'simplify-upstream'
        parameters = @{
            upstreamBranches = $resultUpstreams[$branch]
            overrideUpstreams = $resultUpstreams
            branchName = $branch
        }
    }
    Assert-Diagnostics $diagnostics
}

$upstreamHash = Invoke-LocalAction @commonParams @{
    type = 'set-upstream'
    parameters = @{
        upstreamBranches = $resultUpstreams
        message = "Release $($source) to $($target)$($comment -eq '' ? '' : " for $($params.comment)")"
    }
}
Assert-Diagnostics $diagnostics

$sourceHash = Get-BranchCommit (Get-RemoteBranchRef $source)

# Finalize:
#    1. Push the following:
#        - Update _upstream
#        - Delete $toRemove branches
#        - If not $cleanupOnly, push $source commitish to $target

$commonParams = @{
    diagnostics = $diagnostics
    dryRun = $dryRun
}

$resultBranches = @{
    "$($config.upstreamBranch)" = $upstreamHash.commit
}
foreach ($branch in $toRemove) {
    $resultBranches[$branch] = $null
}
if (-not $cleanupOnly) {
    $resultBranches[$target] = $sourceHash
}

Invoke-FinalizeAction @commonParams @{
    type = 'set-branches'
    parameters = @{
        branches = $resultBranches
    }
}
Assert-Diagnostics $diagnostics
