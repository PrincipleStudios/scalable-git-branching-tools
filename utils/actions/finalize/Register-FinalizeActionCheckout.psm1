Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-FinalizeActionCheckout([PSObject] $finalizeActions) {
    $finalizeActions['checkout'] = {
        param(
            [string] $HEAD,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        # TODO: pass diagnostics
        Invoke-CheckoutBranch $HEAD -quiet
    }
}

Export-ModuleMember -Function Register-FinalizeActionCheckout
