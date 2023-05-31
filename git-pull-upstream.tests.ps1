BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1";
}

Describe 'git-pull-upstream' {
    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGit
            Initialize-UpstreamBranches @{ 'feature/FOO-123' = @("main", "infra/add-services") }
        }

        It 'fails if no branch is checked out' {
            Initialize-NoCurrentBranch

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Must have a branch checked out'
        }

        It 'fails if the working directory is not clean' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-DirtyWorkingDirectory

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Git working directory is not clean.'
        }

        It 'merges all upstream branches for the current branch' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-CleanWorkingDirectory
            Initialize-InvokeMergeSuccess 'origin/main'
            Initialize-InvokeMergeSuccess 'origin/infra/add-services'

            & $PSScriptRoot/git-pull-upstream.ps1
        }
    }

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-UpdateGit
            Initialize-UpstreamBranches @{ 'feature/FOO-123' = @("main", "infra/add-services") }
        }

        It 'fails if no branch is checked out' {
            Initialize-NoCurrentBranch

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Must have a branch checked out'
        }

        It 'fails if the working directory is not clean' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-DirtyWorkingDirectory

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw 'Git working directory is not clean.'
        }

        It 'merges all upstream branches for the current branch' {
            Initialize-CurrentBranch 'feature/FOO-123'
            Initialize-CleanWorkingDirectory
            Initialize-InvokeMergeSuccess 'main'
            Initialize-InvokeMergeSuccess 'infra/add-services'

            & $PSScriptRoot/git-pull-upstream.ps1
        }
    }
}
