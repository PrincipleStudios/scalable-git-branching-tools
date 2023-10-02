Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-LocalActionCreateBranch([PSObject] $localActions) {
    $localActions['create-branch'] = {
        param(
            [string] $target,
            [string[]] $upstreamBranches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        Assert-CleanWorkingDirectory $diagnostics
        if (Get-HasErrorDiagnostic $diagnostics) { return $nil }

        # TODO: update these to use diagnostics
        Invoke-PreserveBranch {
            Invoke-CreateBranch $target $upstreamBranches[0]
            Invoke-CheckoutBranch $target
            Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
            $(Invoke-MergeBranches ($upstreamBranches | Select-Object -skip 1) -quiet).ThrowIfInvalid()
        }

        $commit = Invoke-ProcessLogs "git rev-parse $target" {
            git rev-parse $target
        } -allowSuccessOutput
        return @{ commit = $commit }
    }
}

Export-ModuleMember -Function Register-LocalActionCreateBranch