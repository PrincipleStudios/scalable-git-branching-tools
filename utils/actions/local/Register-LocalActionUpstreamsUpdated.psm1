Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-UpstreamsUpdatedLocalAction {
    param(
        [Parameter()][AllowEmptyCollection()][string[]] $branches,
        [Parameter()][AllowNull()] $overrideUpstreams,
        [Parameter()][bool] $recurse = $false,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    $selectStandardParams = @{
        recurse = $recurse
        overrideUpstreams = $overrideUpstreams
    }
    $config = Get-Configuration
    $prefix = $config.remote ? "refs/remotes/$($config.remote)" : "refs/heads/"

    $needsUpdate = @{}
    $isUpdated = @()
    $noUpstreams = @()
    foreach ($branch in $branches) {
        $upstreams = Select-UpstreamBranches -branch $branch @selectStandardParams
        if (-not $upstreams) {
            $noUpstreams += $branch
            continue
        }
        $target = "$prefix/$branch"
        [string[]]$fullyQualifiedUpstreams = $upstreams | ForEach-Object { "$prefix/$_" }
        [string[]]$upstreamResults = Invoke-ProcessLogs "git for-each-ref --format=`"%(refname:lstrip=3) %(ahead-behind:$target)`" $fullyQualifiedUpstreams" {
            git for-each-ref --format="%(refname:lstrip=3) %(ahead-behind:$target)" @fullyQualifiedUpstreams
        } -allowSuccessOutput
        $outOfDate = ($upstreamResults | Where-Object { ($_ -split ' ')[1] -gt 0 } | ForEach-Object { ($_ -split ' ')[0] })
        if ($outOfDate.Count -gt 0) {
            $needsUpdate[$branch] = $outOfDate
        } else {
            $isUpdated += $branch
        }
    }

    return @{
        noUpstreams = $noUpstreams
        needsUpdate = $needsUpdate
        isUpdated = $isUpdated
    }
}

Export-ModuleMember -Function Invoke-UpstreamsUpdatedLocalAction
