Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionAssertUpdated.psm1"

function Initialize-LocalActionAssertUpdatedSuccess(
    [Parameter()][string] $downstream,
    [Parameter()][string] $upstream
) {
    $config = Get-Configuration
    if ($null -ne $config.remote) {
        if ($null -ne $downstream -AND '' -ne $downstream) {
            $downstream = "$($config.remote)/$downstream"
        }
        if ($null -ne $upstream -AND '' -ne $upstream) {
            $upstream = "$($config.remote)/$upstream"
        }
    }

    Initialize-MergeTogether `
        -allBranches @($upstream) `
        -successfulBranches @() `
        -noChangeBranches @($upstream) `
        -source $downstream `
        -messageTemplate 'Verification Only' `
        -resultCommitish 'result-commitish'
}

function Initialize-LocalActionAssertUpdatedFailure(
    [Parameter()][string] $downstream,
    [Parameter()][string] $upstream,
    [switch] $withConflict
) {
    
    $config = Get-Configuration
    if ($null -ne $config.remote) {
        if ($null -ne $downstream -AND '' -ne $downstream) {
            $downstream = "$($config.remote)/$downstream"
        }
        if ($null -ne $upstream -AND '' -ne $upstream) {
            $upstream = "$($config.remote)/$upstream"
        }
    }

    if ($withConflict) {
        Initialize-MergeTogether `
            -allBranches @($upstream) `
            -successfulBranches @() `
            -noChangeBranches @() `
            -source $downstream `
            -messageTemplate 'Verification Only' `
            -resultCommitish 'result-commitish'
    } else {
        Initialize-MergeTogether `
            -allBranches @($upstream) `
            -successfulBranches @($upstream) `
            -noChangeBranches @() `
            -source $downstream `
            -messageTemplate 'Verification Only' `
            -resultCommitish 'result-commitish'
    }
}

Export-ModuleMember -Function Initialize-LocalActionAssertUpdatedSuccess, Initialize-LocalActionAssertUpdatedFailure
