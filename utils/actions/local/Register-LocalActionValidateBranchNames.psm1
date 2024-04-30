Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.psm1"

function Invoke-AssertBranchNamesLocalAction {
        param(
            [string[]] $branches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $branches | Assert-ValidBranchName -diagnostics $diagnostics
        
        return @{}
}

Export-ModuleMember -Function Invoke-AssertBranchNamesLocalAction
