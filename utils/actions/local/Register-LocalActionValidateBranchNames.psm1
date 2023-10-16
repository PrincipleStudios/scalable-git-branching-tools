Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.psm1"

function Register-LocalActionValidateBranchNames([PSObject] $localActions) {
    $localActions['validate-branch-names'] = {
        param(
            [string[]] $branches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $branches | Assert-ValidBranchName -diagnostics $diagnostics
        
        return @{}
    }
}

Export-ModuleMember -Function Register-LocalActionValidateBranchNames
