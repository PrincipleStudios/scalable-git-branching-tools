Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

# TODO: should check out the branch from remote as a local tracking branch
function Invoke-CheckoutFinalizeAction{
    param(
        [string] $HEAD,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
        [switch] $dryRun
    )

    if ($dryRun) {
        "git checkout $HEAD"
        return
    }
    Assert-CleanWorkingDirectory -diagnostics $diagnostics
    if (-not (Get-HasErrorDiagnostic $diagnostics)) {
        Invoke-CheckoutBranch $HEAD -diagnostics $diagnostics
    }
}

Export-ModuleMember -Function Invoke-CheckoutFinalizeAction
