Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionMergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"

function Initialize-LocalActionMergeBranches(
    [Parameter(Mandatory)][string[]] $upstreamBranches,
    [AllowEmptyCollection()][string[]] $successfulBranches,
    [AllowEmptyCollection()][string[]] $noChangeBranches,
    [Parameter()][Hashtable] $initialCommits = @{},
    [Parameter()][string] $resultCommitish,
    [Parameter()][string] $mergeMessageTemplate,
    [Parameter()][string] $source,
    [Switch] $sourceFailed
) {
    $config = Get-Configuration
    if ($null -ne $config.remote) {
        $upstreamBranches = [string[]]$upstreamBranches | Foreach-Object { "$($config.remote)/$_" }
        $successfulBranches = [string[]]$successfulBranches | Where-Object { $_ } | Foreach-Object { "$($config.remote)/$_" }
        $noChangeBranches = [string[]]$noChangeBranches | Where-Object { $_ } | Foreach-Object { "$($config.remote)/$_" }
        if ($null -ne $source -AND '' -ne $source) {
            $source = "$($config.remote)/$source"
        }
    }

    if ($sourceFailed) {
        Initialize-MergeTogetherAllFailed @($source)
        return
    }

    Initialize-MergeTogether -allBranches $upstreamBranches -successfulBranches $successfulBranches -noChangeBranches $noChangeBranches `
        -initialCommits $initialCommits `
        -source $source `
        -messageTemplate $mergeMessageTemplate `
        -resultCommitish $resultCommitish
}

function Initialize-LocalActionMergeBranchesFailure(
    [Parameter(Mandatory)][string[]] $upstreamBranches,
    [Parameter(Mandatory)][string[]] $failures,
    [Parameter(Mandatory)][string] $resultCommitish,
    [Parameter(Mandatory)][string] $mergeMessageTemplate,
    [Parameter()][string] $source
) {
    $successfulBranches = ($upstreamBranches | Where-Object { $_ -notin $failures })
    Initialize-LocalActionMergeBranches `
        -upstreamBranches $upstreamBranches `
        -successfulBranches $successfulBranches `
        -resultCommitish $resultCommitish `
        -mergeMessageTemplate $mergeMessageTemplate `
        -source $source `
        -sourceFailed:($source -in $failures)
}

function Initialize-LocalActionMergeBranchesSuccess(
    [Parameter(Mandatory)][string[]] $upstreamBranches,
    [Parameter(Mandatory)][string] $resultCommitish,
    [Parameter(Mandatory)][string] $mergeMessageTemplate,
    [Parameter()][string] $source,
    [Parameter()][int] $failAtMerge = -1,
    [Parameter()][string[]] $failedBranches
) {
    [string[]]$successfulBranches = $failAtMerge -eq -1 -AND -not $failedBranches ? $upstreamBranches
        : $failedBranches ? ($upstreamBranches | Where-Object { $failedBranches -notcontains $_ })
        : $failAtMerge -eq 0 ? @()
        : ($upstreamBranches | Select-Object -First $failAtMerge)
    Initialize-LocalActionMergeBranches `
        -upstreamBranches $upstreamBranches `
        -successfulBranches $successfulBranches `
        -resultCommitish $resultCommitish `
        -mergeMessageTemplate $mergeMessageTemplate `
        -source $source
}

Export-ModuleMember -Function Initialize-LocalActionMergeBranches, Initialize-LocalActionMergeBranchesFailure,Initialize-LocalActionMergeBranchesSuccess
