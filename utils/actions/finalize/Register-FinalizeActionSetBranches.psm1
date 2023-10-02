Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-FinalizeActionSetBranches([PSObject] $finalizeActions) {
    $finalizeActions['set-branches'] = {
        param(
            [Hashtable] $branches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        # TODO
    }
}

Export-ModuleMember -Function Register-FinalizeActionSetBranches
