Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-FinalizeActionCheckout([PSObject] $finalizeActions) {
    $finalizeActions['checkout'] = {
        param(
            [string] $HEAD,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        Invoke-CheckoutBranch $HEAD -diagnostics $diagnostics
    }
}

Export-ModuleMember -Function Register-FinalizeActionCheckout
