BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Assert-BranchPushed.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Assert-BranchPushed.mocks.psm1"
}

Describe 'Assert-BranchPushed' {
    $noLocalBranch = 'Branch my-branch does not exist locally. '
    $noUpstreamError = 'Branch my-branch does not have a remote tracking branch. '
    $notPushedError = 'Branch my-branch has changes not pushed to origin/my-branch. '
    $extraMessage = 'Please try again.'

    # TODO - these are not correct
    It 'does nothing if no remote is set' {
        Initialize-ToolConfiguration -noRemote
        Assert-BranchPushed my-branch
    }

    It 'does nothing when no remote tracking is set by default' {
        Initialize-ToolConfiguration
        Initialize-BranchNoUpstream my-branch
        Assert-BranchPushed my-branch
    }

    It 'fails when a remote tracking is not set if requested' {
        Initialize-ToolConfiguration
        Initialize-BranchNoUpstream my-branch
        { Assert-BranchPushed my-branch -failIfNoUpstream } | Should -Throw $noUpstreamError -Because 'no remote tracking branch was set'
    }

    It 'does nothing when the remote tracking is up-to-date with the local branch' {
        Initialize-ToolConfiguration
        Initialize-BranchPushed my-branch
        Assert-BranchPushed my-branch
    }

    It 'ignores -failIfNoUpstream if there is an upstream' {
        Initialize-ToolConfiguration
        Initialize-BranchPushed my-branch
        Assert-BranchPushed my-branch -failIfNoUpstream
    }

    It 'fails when the remote tracking is not up-to-date with the local branch' {
        Initialize-ToolConfiguration
        Initialize-BranchNotPushed my-branch
        { Assert-BranchPushed my-branch } | Should -Throw $notPushedError -Because 'the remote tracking branch was not up-to-date'
    }

    It 'includes the message for no-upstream' {
        Initialize-ToolConfiguration
        Initialize-BranchNoUpstream my-branch
        { Assert-BranchPushed my-branch -failIfNoUpstream -message $extraMessage }
            | Should -Throw "$noUpstreamError$extraMessage" -Because 'no remote tracking branch was set'
    }

    It 'includes the message for not-pushed' {
        Initialize-ToolConfiguration
        Initialize-BranchNotPushed my-branch
        { Assert-BranchPushed my-branch -message $extraMessage }
            | Should -Throw "$notPushedError$extraMessage" -Because 'the remote tracking branch was not up-to-date'
    }

    It 'does nothing if the local branch does not exist' {
        Initialize-ToolConfiguration
        Initialize-BranchDoesNotExist my-branch
        Assert-BranchPushed my-branch
    }

    It 'fails if the local branch does not exist and requested' {
        Initialize-BranchDoesNotExist my-branch
        { Assert-BranchPushed my-branch -failIfNoBranch }
            | Should -Throw "$noLocalBranch" -Because "local branch was required"
    }

    It 'fails with message if the local branch does not exist and requested' {
        Initialize-BranchDoesNotExist my-branch
        { Assert-BranchPushed my-branch -failIfNoBranch -m $extraMessage }
            | Should -Throw "$noLocalBranch$extraMessage" -Because "local branch was required"
    }
}
