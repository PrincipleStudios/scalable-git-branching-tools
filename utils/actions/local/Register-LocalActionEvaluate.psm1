Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionEvaluate([PSObject] $localActions) {
    $localActions['evaluate'] = {
        param(
            [Parameter(Mandatory)][object] $result,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )
        
        return $result
    }
}

Export-ModuleMember -Function Register-LocalActionEvaluate
