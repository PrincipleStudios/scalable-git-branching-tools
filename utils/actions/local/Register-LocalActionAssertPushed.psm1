Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionAssertPushed([PSObject] $localActions) {
    $localActions['assert-pushed'] = {
        param(
            [Parameter()][string] $target,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $state = Get-BranchSyncState $target

        $disallowed = @('>', '<>')
        if ($disallowed -contains $state) {
            Add-ErrorDiagnostic $diagnostics "The local branch for $target has changes that are not pushed to the remote"
        }
        
        return @{}
    }
}

Export-ModuleMember -Function Register-LocalActionAssertPushed
