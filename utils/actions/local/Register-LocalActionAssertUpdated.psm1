Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-LocalActionAssertUpdated([PSObject] $localActions) {
    $localActions['assert-updated'] = {
        param(
            [Parameter()][string] $downstream,
            [Parameter()][string] $upstream,
            [hashtable] $commitMappingOverride = @{},

            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $config = Get-Configuration
        if ($null -ne $config.remote) {
            if ($null -ne $downstream -AND '' -ne $downstream) {
                $downstream = "$($config.remote)/$downstream"
            }
            if ($null -ne $upstream -AND '' -ne $upstream) {
                $upstream = "$($config.remote)/$upstream"
            }
        }

        # Verifies that everything in "upstream" is in "downstream". Asserts if not.
        $mergeResult = Invoke-MergeTogether `
            -source $downstream `
            -commitishes @($upstream) `
            -messageTemplate 'Verification Only' `
            -commitMappingOverride $commitMappingOverride `
            -diagnostics $diagnostics `
            -noFailureMessages
        if ($mergeResult.failed) {
            Add-ErrorDiagnostic $diagnostics "The branch $downstream conflicts with $upstream"
        } elseif ($mergeResult.hasChanges) {
            Add-ErrorDiagnostic $diagnostics "The branch $downstream has changes that are not in $upstream"
        }
        
        return @{}
    }
}

Export-ModuleMember -Function Register-LocalActionAssertUpdated
