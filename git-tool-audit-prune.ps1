#!/usr/bin/env pwsh

Param(
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
# Get all branches in upstreams

$originalUpstreams = Invoke-LocalAction @commonParams @{
    type = 'get-all-upstreams'
    parameters= @{}
}
Assert-Diagnostics $diagnostics

# Get branches that actually exist

$allBranches = Select-Branches

# For all keys (downstream) in the upstreams:
#    - If the downstream does not exist, replace it with its downstreams in all other upstreams

[string[]]$configuredBranches = @() + $originalUpstreams.Keys
$resultUpstreams = @{}
foreach ($branch in $configuredBranches) {
    if ($branch -in $allBranches) { continue }
    [string[]]$upstreams = $resultUpstreams[$branch] ?? $originalUpstreams[$branch]
    foreach ($downstream in $configuredBranches) {
        [string[]]$initial = $resultUpstreams[$downstream] ?? $originalUpstreams[$downstream]
        if ($branch -notin $initial) { continue }
        $resultUpstreams[$downstream] = Invoke-LocalAction @commonParams @{
            type = 'filter-branches'
            parameters = @{
                include = $initial + $upstreams
                exclude = @($branch)
            }
        }
    }
}

Write-Host (ConvertTo-Json $resultUpstreams)


# For all keys (downstream) in the upstreams:
#    - Remove entire branch configuration if the branch does not exist
#    - Remove upstreams that do not exist
foreach ($branch in $configuredBranches) {
    if ($branch -notin $allBranches) {
        $resultUpstreams[$branch] = $null
        continue
    }
    [string[]]$upstreams = $resultUpstreams[$branch] ?? $originalUpstreams[$branch]
    [string[]]$resultUpstream = @()
    foreach ($upstream in $upstreams) {
        if ($upstream -in $allBranches) {
            $resultUpstream = $resultUpstream + @($upstream)
        }
    }
}

# Simplify changed upstreams
foreach ($branch in $configuredBranches) {
    if (-not $resultUpstreams[$branch]) { continue }
    [string[]]$result = Invoke-LocalAction @commonParams @{
        type = 'simplify-upstream'
        parameters = @{
            upstreamBranches = $resultUpstreams[$branch]
            overrideUpstreams = $resultUpstreams
            branchName = $branch
        }
    }
    if ($result.length -ne ([string[]]$resultUpstreams[$branch]).length) {
        $resultUpstreams[$branch] = $result
    }
}
Assert-Diagnostics $diagnostics

Write-Host (ConvertTo-Json $resultUpstreams)

# Set upstream branch

if ($resultUpstreams.Count -ne 0) {
    $upstreamHash = Invoke-LocalAction @commonParams @{
        type = 'set-upstream'
        parameters = @{
            upstreamBranches = $resultUpstreams
            message = "Applied changes from 'simplify' audit"
        }
    }
    Assert-Diagnostics $diagnostics
}

# Finalize: Push upstream branch

$commonParams = @{
    diagnostics = $diagnostics
    dryRun = $dryRun
}

if ($resultUpstreams.Count -ne 0) {
    Invoke-FinalizeAction @commonParams @{
        type = 'set-branches'
        parameters = @{
            branches = @{
                "$($config.upstreamBranch)" = $upstreamHash.commit
            }
        }
    }
    Assert-Diagnostics $diagnostics
}
