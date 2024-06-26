Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-EvaluateLocalAction {
    param(
        [Parameter(Mandatory)][AllowNull()][object] $result,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    return $result
}

Export-ModuleMember -Function Invoke-EvaluateLocalAction
