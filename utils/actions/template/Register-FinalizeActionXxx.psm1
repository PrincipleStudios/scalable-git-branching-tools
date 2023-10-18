Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-FinalizeActionXxx([PSObject] $finalizeActions) {
    $finalizeActions['xxx'] = {
        param(
            # TODO: add parameters
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        return @{}
    }
}

Export-ModuleMember -Function Register-FinalizeActionSetBranches
