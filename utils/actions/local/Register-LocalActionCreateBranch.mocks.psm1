Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionCreateBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"



function Initialize-LocalActionCreateBranchSuccess(
    [Parameter(Mandatory)][string] $target, 
    [Parameter(Mandatory)][string[]] $upstreamBranches, 
    [Parameter(Mandatory)][string] $resultCommitish
) {
    Initialize-CleanWorkingDirectory
    Initialize-NoCurrentBranch
    Initialize-PreserveBranchCleanup -detachedHead 'baadf00d'

    Initialize-CreateBranch $target $upstreamBranches[0]
    Initialize-CheckoutBranch $target

    for ($i = 1; $i -lt $upstreamBranches.Count; $i++) {
        Initialize-InvokeMergeSuccess $upstreamBranches[$i]
    }

    Invoke-MockGitModule -ModuleName Register-LocalActionCreateBranch "rev-parse $target" -MockWith $resultCommitish
}

Export-ModuleMember -Function Initialize-LocalActionCreateBranchSuccess
