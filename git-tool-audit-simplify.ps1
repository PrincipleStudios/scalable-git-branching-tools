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
# For all branches:
#    Simplify

$originalUpstreams = Invoke-LocalAction @commonParams @{
    type = 'get-all-upstreams'
    parameters= @{}
}
Assert-Diagnostics $diagnostics

$resultUpstreams = @{}
foreach ($branch in $originalUpstreams.Keys) {
    if (-not $originalUpstreams[$branch]) { continue }
    [string[]]$result = Invoke-LocalAction @commonParams @{
        type = 'simplify-upstream'
        parameters = @{
            upstreamBranches = $originalUpstreams[$branch]
            overrideUpstreams = $originalUpstreams
            branchName = $branch
        }
    }
    if ($result.length -ne ([string[]]$originalUpstreams[$branch]).length) {
        $resultUpstreams[$branch] = $result
    }
}
Assert-Diagnostics $diagnostics

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

# Finalize:
#    Push the new _upstream

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
