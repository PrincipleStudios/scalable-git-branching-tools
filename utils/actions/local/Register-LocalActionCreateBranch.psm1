Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git/Set-GitFiles.psm1"

function Register-LocalActionCreateBranch([PSObject] $localActions) {
    $localActions['create-branch'] = {
        param(
            [string] $target,
            [string[]] $upstreamBranches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        # Invoke-PreserveBranch {
        #     Invoke-CreateBranch $target $upstreamBranches[0]
        #     Invoke-CheckoutBranch $target
        #     Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
        #     $(Invoke-MergeBranches ($upstreamBranches | Select-Object -skip 1)).ThrowIfInvalid()

        #     return @{ commit = (git rev-parse $target) }
        # }

        # return @{
        #     commit = $commit
        # }
    }
}

Export-ModuleMember -Function Register-LocalActionCreateBranch
