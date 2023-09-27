BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}
}


Describe 'git-verify-updated' {
    BeforeEach {
        Register-Framework
    }

    It 'fails if no current branch and none provided' {
        Initialize-ToolConfiguration -noRemote
        Initialize-NoCurrentBranch

        { & $PSScriptRoot/git-verify-updated.ps1 } | Should -Throw
    }

    It 'uses the default branch when none specified, without a remote' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CurrentBranch 'feature/PS-2'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'feature/PS-1'
            'infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1
    }

    It 'uses the branch specified, without a remote' {
        Initialize-ToolConfiguration -noRemote

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'feature/PS-1'
            'infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2
    }

    It 'throws when one branch is out of date' {
        Initialize-ToolConfiguration -noRemote

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'feature/PS-1'
            'infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "other-hash" }

        { & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2 } | Should -Throw
    }

    It 'uses the current branch if none specified, with a remote' {
        Initialize-ToolConfiguration
        Initialize-CurrentBranch 'feature/PS-2'
        Initialize-BranchPushed 'feature/PS-2'
        Initialize-UpdateGitRemote

        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify feature/PS-2' } { 'target-branch-hash' }

        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse } {
            'origin/feature/PS-1'
            'origin/infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1
    }

    It 'uses the current branch if none specified, with a remote, but fails if not pushed' {
        Initialize-ToolConfiguration
        Initialize-CurrentBranch 'feature/PS-2'
        Initialize-BranchNotPushed 'feature/PS-2'
        Initialize-UpdateGitRemote

        { & $PSScriptRoot/git-verify-updated.ps1 }
            | Should -Throw "Branch feature/PS-2 has changes not pushed to origin/feature/PS-2. Please ensure changes are pushed (or reset) and try again."
    }

    It 'uses the current branch if none specified, with a remote, but fails if not tracked to the remote' {
        Initialize-ToolConfiguration
        Initialize-CurrentBranch 'feature/PS-2'
        Initialize-BranchNoUpstream 'feature/PS-2'
        Initialize-UpdateGitRemote

        { & $PSScriptRoot/git-verify-updated.ps1 }
            | Should -Throw "Branch feature/PS-2 does not have a remote tracking branch. Please ensure changes are pushed (or reset) and try again."
    }

    It 'uses the branch specified, with a remote' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-BranchPushed 'feature/PS-2'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/feature/PS-2' } { 'target-branch-hash' }

        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND -not $recurse} {
            'origin/feature/PS-1'
            'origin/infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2
    }

    It 'uses the branch specified, recursively, with a remote' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-BranchPushed 'feature/PS-2'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/feature/PS-2' } { 'target-branch-hash' }

        Mock -CommandName Select-UpstreamBranches -ParameterFilter { $branchName -eq 'feature/PS-2' -AND $includeRemote -AND $recurse } {
            'origin/feature/PS-1'
            'origin/infra/build-improvements'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/feature/PS-1" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base feature-PS1-branch-hash target-branch-hash" } { "feature-PS1-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "rev-parse --verify origin/infra/build-improvements" } { "infra-branch-hash" }
        Mock git -ParameterFilter { ($args -join ' ') -eq "merge-base infra-branch-hash target-branch-hash" } { "infra-branch-hash" }

        & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2 -recurse
    }

}
