Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionSimplifyUpstreamBranches([PSObject] $localActions) {
    $localActions['simplify-upstream'] = {
        param(
            [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $upstreamBranches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )
        
        $upstreamBranches | Assert-ValidBranchName -diagnostics $diagnostics
        if (Get-HasErrorDiagnostic $diagnostics) { return $null }

        if ($upstreamBranches.Count -eq 0) {
            $config = Get-Configuration
            if ($null -eq $config.defaultServiceLine) {
                Add-ErrorDiagnostic $diagnostics 'At least one upstream branch must be specified or the default service line must be set'
            }
            # default to service line if none provided and config has a service line
            return @( $config.defaultServiceLine )
        }

        $result = Compress-UpstreamBranches $upstreamBranches -diagnostics $diagnostics
        return $result
    }
}

Export-ModuleMember -Function Register-LocalActionSimplifyUpstreamBranches
