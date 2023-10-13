Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionCreateBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"

function Initialize-LocalActionCreateBranchSuccess(
    [Parameter(Mandatory)][string[]] $upstreamBranches, 
    [Parameter(Mandatory)][string] $resultCommitish,
    [Parameter(Mandatory)][string] $mergeMessageTemplate,
    [Parameter()][int] $failAtMerge = -1
) {
    $config = Get-Configuration
    if ($null -ne $config.remote) {
        $upstreamBranches = [string[]]$upstreamBranches | Foreach-Object { "$($config.remote)/$_" }
    }

    $successfulBranches = $failAtMerge -eq -1 ? $upstreamBranches
        : $failAtMerge -eq 0 ? @()
        : ($upstreamBranches | Select-Object -First $failAtMerge)

    Initialize-MergeTogether $upstreamBranches $successfulBranches `
        -messageTemplate $mergeMessageTemplate `
        -resultCommitish $resultCommitish
}

Export-ModuleMember -Function Initialize-LocalActionCreateBranchSuccess
