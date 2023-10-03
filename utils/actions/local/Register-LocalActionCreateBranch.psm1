Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

# TODO: this action has a side effect that creates the local branch.
# TODO: this assumes all branches are remotes (if remote is specified)
function Register-LocalActionCreateBranch([PSObject] $localActions) {
    $localActions['create-branch'] = {
        param(
            [string] $target,
            [string[]] $upstreamBranches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $config = Get-Configuration
        if ($null -ne $config.remote) {
            $upstreamBranches = [string[]]$upstreamBranches | Foreach-Object { "$($config.remote)/$_" }
        }
        Assert-CleanWorkingDirectory $diagnostics
        if (Get-HasErrorDiagnostic $diagnostics) { return $nil }

        # TODO: update these to use diagnostics
        Invoke-PreserveBranch {
            Invoke-CreateBranch $target $upstreamBranches[0]
            Invoke-CheckoutBranch $target -diagnostics $diagnostics
            Assert-CleanWorkingDirectory -diagnostics $diagnostics # checkouts can change ignored files; reassert clean
            if (Get-HasErrorDiagnostic $diagnostics) { return }

            try {
                # TODO - use diagnostics and record output to processlog
                $(Invoke-MergeBranches ($upstreamBranches | Select-Object -skip 1) -quiet).ThrowIfInvalid() *> $null
            } catch {
                Add-ErrorDiagnostic $diagnostics "Failed to merge all branches"
            }
        }

        if (Get-HasErrorDiagnostic $diagnostics) { return }

        $commit = Invoke-ProcessLogs "git rev-parse $target" {
            git rev-parse $target
        } -allowSuccessOutput -quiet
        return @{ commit = $commit }
    }
}

Export-ModuleMember -Function Register-LocalActionCreateBranch
