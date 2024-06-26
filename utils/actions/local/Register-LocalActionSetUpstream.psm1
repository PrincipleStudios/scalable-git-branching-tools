Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Invoke-SetUpstreamLocalAction {
    param(
        [PSObject] $upstreamBranches,
        [string] $message,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )
    $upstreamBranch = Get-UpstreamBranch
    $ht = ConvertTo-Hashtable $upstreamBranches
    $contents = $ht.Keys | ConvertTo-HashMap -getValue {
        if ($null -eq $ht[$_] -OR $ht[$_].length -eq 0) { return $null }
        "$(($ht[$_] | Where-Object { $_ }) -join "`n")`n"
    }

    $commit = Set-GitFiles $contents -m $message -initialCommitish $upstreamBranch
    if ($null -eq $commit) {
        throw "Set-GitFiles was unable to create a new commit."
    }
    return @{
        commit = $commit
    }
}

Export-ModuleMember -Function Invoke-SetUpstreamLocalAction
