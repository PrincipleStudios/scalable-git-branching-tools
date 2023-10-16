Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionGetUpstream([PSObject] $localActions) {
    $localActions['get-upstream'] = {
        param(
            [Parameter(Mandatory)][string] $target,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        [string[]]$result = Select-UpstreamBranches -branchName $target
        
        return $result
    }
}

Export-ModuleMember -Function Register-LocalActionGetUpstream
