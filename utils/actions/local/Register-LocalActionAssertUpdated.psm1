Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-LocalActionAssertUpdated([PSObject] $localActions) {
    $localActions['assert-updated'] = ${function:Invoke-AssertBranchUpToDateLocalAction}
}

function Invoke-AssertBranchUpToDateLocalAction {
    param(
        [Parameter()][string] $downstream,
        [Parameter()][string] $upstream,
        [hashtable] $commitMappingOverride = @{},

        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    # Verifies that everything in "upstream" is in "downstream". Asserts if not.
    $mergeResult = Invoke-MergeTogether `
        -source (Get-RemoteBranchRef $downstream) `
        -commitishes @(Get-RemoteBranchRef $upstream) `
        -messageTemplate 'Verification Only' `
        -commitMappingOverride $commitMappingOverride `
        -diagnostics $diagnostics `
        -noFailureMessages
    if ($mergeResult.failed) {
        Add-ErrorDiagnostic $diagnostics "The branch $upstream conflicts with $downstream"
    } elseif ($mergeResult.hasChanges) {
        Add-ErrorDiagnostic $diagnostics "The branch $upstream has changes that are not in $downstream"
    }
    
    return @{}
}

Export-ModuleMember -Function Register-LocalActionAssertUpdated
