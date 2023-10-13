Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionXxx([PSObject] $localActions) {
    $localActions['xxx'] = {
        param(
            # TODO: add parameters
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )
        
        return @{}
    }
}

Export-ModuleMember -Function Register-LocalActionXxx
