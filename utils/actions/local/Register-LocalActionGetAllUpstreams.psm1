Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-GetAllUpstreamsLocalAction {
    param(
        [Parameter()][AllowNull()] $overrideUpstreams,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    return Select-AllUpstreamBranches -overrideUpstreams:$overrideUpstreams
}

Export-ModuleMember -Function Invoke-GetAllUpstreamsLocalAction
