Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

# TODO: this assumes all branches are remotes (if remote is specified)
function Register-LocalActionCreateBranch([PSObject] $localActions) {
    $localActions['create-branch'] = {
        param(
            [string[]] $upstreamBranches,
            [string] $mergeMessageTemplate,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $config = Get-Configuration
        if ($null -ne $config.remote) {
            $upstreamBranches = [string[]]$upstreamBranches | Foreach-Object { "$($config.remote)/$_" }
        }

        $mergeResult = Invoke-MergeTogether $upstreamBranches -messageTemplate $mergeMessageTemplate -diagnostics $diagnostics -asWarnings
        $commit = $mergeResult.result
        if ($null -eq $commit) {
            Add-ErrorDiagnostic $diagnostics "No branches could be resolved to merge"
        }
        # TODO - output successfully merged branches
        return @{ commit = $commit }
    }
}

Export-ModuleMember -Function Register-LocalActionCreateBranch
