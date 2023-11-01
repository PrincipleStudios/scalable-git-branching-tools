Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionMergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"

function Initialize-LocalActionMergeBranchesFailure(
    [Parameter(Mandatory)][string[]] $upstreamBranches,
    [Parameter(Mandatory)][string[]] $failures,
    [Parameter(Mandatory)][string] $resultCommitish,
    [Parameter(Mandatory)][string] $mergeMessageTemplate,
    [Parameter()][string] $source
) {
    $config = Get-Configuration
    if ($null -ne $config.remote) {
        $upstreamBranches = [string[]]$upstreamBranches | Foreach-Object { "$($config.remote)/$_" }
        $failures = [string[]]$failures | Foreach-Object { "$($config.remote)/$_" }
        if ($null -ne $source -AND '' -ne $source) {
            $source = "$($config.remote)/$source"
        }
    }

    $successfulBranches = ($upstreamBranches | Where-Object { $_ -notin $failures })
    if ($source -in $failures) {
        Initialize-MergeTogetherAllFailed @($source)
        return
    }

    Initialize-MergeTogether -allBranches $upstreamBranches -successfulBranches $successfulBranches `
        -source $source `
        -messageTemplate $mergeMessageTemplate `
        -resultCommitish $resultCommitish
}

function Initialize-LocalActionMergeBranchesSuccess(
    [Parameter(Mandatory)][string[]] $upstreamBranches,
    [Parameter(Mandatory)][string] $resultCommitish,
    [Parameter(Mandatory)][string] $mergeMessageTemplate,
    [Parameter()][string] $source,
    [Parameter()][int] $failAtMerge = -1,
    [Parameter()][string[]] $failedBranches
) {
    $config = Get-Configuration
    if ($null -ne $config.remote) {
        $upstreamBranches = [string[]]$upstreamBranches | Foreach-Object { "$($config.remote)/$_" }
        if ($null -ne $source -AND '' -ne $source) {
            $source = "$($config.remote)/$source"
        }
        if ($failedBranches) {
            $failedBranches = [string[]]$failedBranches | Foreach-Object { "$($config.remote)/$_" }
        }
    }

    [string[]]$successfulBranches = $failAtMerge -eq -1 -AND -not $failedBranches ? $upstreamBranches
        : $failedBranches ? ($upstreamBranches | Where-Object { $failedBranches -notcontains $_ })
        : $failAtMerge -eq 0 ? @()
        : ($upstreamBranches | Select-Object -First $failAtMerge)

    Initialize-MergeTogether -allBranches $upstreamBranches -successfulBranches $successfulBranches `
        -source $source `
        -messageTemplate $mergeMessageTemplate `
        -resultCommitish $resultCommitish
}

Export-ModuleMember -Function Initialize-LocalActionMergeBranchesFailure,Initialize-LocalActionMergeBranchesSuccess
