BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1";
    Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.mocks.psm1";
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.mocks.psm1";
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1";

    Initialize-QuietMergeBranches
}

Describe 'git-pull-upstream' {
    BeforeEach {
        Register-Framework
    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-UpstreamBranches @{ 'feature/FOO-123' = @("main", "infra/add-services") }
            Initialize-UpstreamBranches @{ 'infra/add-services' = @("main") }
        }

        It 'fails if no branch is checked out' {
            Initialize-NoCurrentBranch

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Must have a branch checked out or specify one.'
        }

        It 'fails if the working directory is not clean' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-DirtyWorkingDirectory
            Initialize-BranchPushed 'feature/FOO-123'

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Git working directory is not clean.'
        }

        It 'merges all upstream branches for the current branch' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-CheckoutBranch 'feature/FOO-123'
            Initialize-CleanWorkingDirectory
            Initialize-InvokeMergeSuccess 'origin/main'
            Initialize-InvokeMergeSuccess 'origin/infra/add-services'
            Initialize-BranchPushed 'feature/FOO-123'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin feature/FOO-123:refs/heads/feature/FOO-123' } { $Global:LASTEXITCODE = 0 }
            Initialize-RestoreGitHead 'feature/FOO-123'

            & $PSScriptRoot/git-pull-upstream.ps1
        }

        It 'ensures the remote is up-to-date' {
            Initialize-CleanWorkingDirectory
            Initialize-CurrentBranch 'feature/FOO-76'
            Initialize-BranchNotPushed 'feature/FOO-76'

            { & ./git-pull-upstream.ps1 }
                | Should -Throw "Branch feature/FOO-76 has changes not pushed to origin/feature/FOO-76. Please ensure changes are pushed (or reset) and try again."
        }

        It 'ensures the remote is tracked' {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-CleanWorkingDirectory
            Initialize-CurrentBranch 'feature/FOO-76'
            Initialize-BranchNoUpstream 'feature/FOO-76'

            { & ./git-pull-upstream.ps1 }
                | Should -Throw "Branch feature/FOO-76 does not have a remote tracking branch. Please ensure changes are pushed (or reset) and try again."
        }

        It "merges all upstream branches for the specified branch when it doesn't exist" {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-BranchDoesNotExist 'infra/add-services'
            Initialize-CheckoutBranch 'infra/add-services'
            Initialize-CleanWorkingDirectory
            Initialize-InvokeMergeSuccess 'origin/main'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin infra/add-services:refs/heads/infra/add-services' } { $Global:LASTEXITCODE = 0 }
            Initialize-RestoreGitHead 'feature/FOO-123'

            & $PSScriptRoot/git-pull-upstream.ps1 'infra/add-services'
        }

        It 'ensures the remote is up-to-date with the specified branch' {
            Initialize-CleanWorkingDirectory
            Initialize-CurrentBranch 'feature/FOO-76'
            Initialize-BranchNotPushed 'infra/add-services'

            { & ./git-pull-upstream.ps1 'infra/add-services' }
                | Should -Throw "Branch infra/add-services has changes not pushed to origin/infra/add-services. Please ensure changes are pushed (or reset) and try again."
        }

        It 'ensures the remote is tracked by the specified branch' {
            Initialize-CleanWorkingDirectory
            Initialize-CurrentBranch 'feature/FOO-76'
            Initialize-BranchNoUpstream 'infra/add-services'

            { & ./git-pull-upstream.ps1 'infra/add-services' }
                | Should -Throw "Branch infra/add-services does not have a remote tracking branch. Please ensure changes are pushed (or reset) and try again."
        }
    }

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-UpdateGitRemote
            Initialize-UpstreamBranches @{ 'feature/FOO-123' = @("main", "infra/add-services") }
        }

        It 'fails if no branch is checked out' {
            Initialize-NoCurrentBranch

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Must have a branch checked out or specify one.'
        }

        It 'fails if the working directory is not clean' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-DirtyWorkingDirectory

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Git working directory is not clean.'
        }

        It 'merges all upstream branches for the current branch' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-CleanWorkingDirectory
            Initialize-CheckoutBranch 'feature/FOO-123'
            Initialize-InvokeMergeSuccess 'main'
            Initialize-InvokeMergeSuccess 'infra/add-services'
            Initialize-RestoreGitHead 'feature/FOO-123'

            & $PSScriptRoot/git-pull-upstream.ps1
        }
    }
}
