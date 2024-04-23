Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionAssertUpdated.psm1"

function Get-CommitsWithRemote(
    [Parameter()][Hashtable] $initialCommits
) {
    return $initialCommits.Keys | ConvertTo-HashMap -getKey { Get-RemoteBranchRef $_ } -getValue { $initialCommits[$_] }
}

function Initialize-LocalActionAssertUpdatedSuccess(
    [Parameter()][string] $downstream,
    [Parameter()][string] $upstream,
    [Parameter()][Hashtable] $initialCommits = @{}
) {
    $resultCommit = $initialCommits[$downstream] ?? 'result-commitish'
    $downstream = Get-RemoteBranchRef $downstream
    $upstream = Get-RemoteBranchRef $upstream

    Initialize-MergeTogether `
        -allBranches @($upstream) `
        -successfulBranches @() `
        -noChangeBranches @($upstream) `
        -initialCommits (Get-CommitsWithRemote $initialCommits) `
        -source $downstream `
        -messageTemplate 'Verification Only' `
        -resultCommitish $resultCommit
}

function Initialize-LocalActionAssertUpdatedFailure(
    [Parameter()][string] $downstream,
    [Parameter()][string] $upstream,
    [Parameter()][Hashtable] $initialCommits = @{},
    [switch] $withConflict
) {
    $resultCommit = $initialCommits[$downstream] ?? 'result-commitish'
    $downstream = Get-RemoteBranchRef $downstream
    $upstream = Get-RemoteBranchRef $upstream

    $base = @{
        allBranches = @($upstream)
        noChangeBranches = @()
        initialCommits = (Get-CommitsWithRemote $initialCommits)
        source = $downstream
        messageTemplate = 'Verification Only'
        resultCommitish = $resultCommit
    }

    if ($withConflict) {
        Initialize-MergeTogether @base `
            -successfulBranches @()
    } else {
        Initialize-MergeTogether @base `
            -successfulBranches @($upstream)
    }
}

Export-ModuleMember -Function Initialize-LocalActionAssertUpdatedSuccess, Initialize-LocalActionAssertUpdatedFailure
