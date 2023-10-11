Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"

function Initialize-FinalizeActionCheckout([string] $HEAD, [switch] $fail) {
    Initialize-CleanWorkingDirectory
    if (-not $fail) {
        Initialize-CheckoutBranch $HEAD
    } else {
        Initialize-CheckoutBranchFailed $HEAD
    }
}

Export-ModuleMember -Function Initialize-FinalizeActionCheckout
