Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-LocalActionSetUpstream([PSObject] $localActions) {
    $localActions['set-upstream'] = {
        param(
            [PSObject] $upstreamBranches,
            [string] $message,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )
        $upstreamBranch = Get-UpstreamBranch
        $ht = ConvertTo-Hashtable $upstreamBranches
        $contents = $ht.Keys | ConvertTo-HashMap -getValue {
            "$(($ht[$_] | Where-Object { $_ }) -join "`n")`n"
        }
        
        $commit = Set-GitFiles $contents -m $message -initialCommitish $upstreamBranch
        return @{
            commit = $commit
        }
    }
}

Export-ModuleMember -Function Register-LocalActionSetUpstream
