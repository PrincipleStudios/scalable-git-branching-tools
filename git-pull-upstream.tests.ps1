BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}
}

Describe 'git-pull-upstream' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.mocks.psm1"
        Initialize-QuietMergeBranches
    }

    It 'works on the current branch' {
        Initialize-ToolConfiguration -noRemote

        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'feature/FOO-76'
        Initialize-BranchPushed 'feature/FOO-76'
        Initialize-UpstreamBranches @{ 'feature/FOO-76' = @("feature/FOO-123","feature/XYZ-1-services") }

        Initialize-InvokeMergeSuccess 'feature/FOO-123'
        Initialize-InvokeMergeSuccess 'feature/XYZ-1-services'

        & ./git-pull-upstream.ps1
    }

    It 'works on the current branch and leaves conflicts' {
        Initialize-ToolConfiguration -noRemote

        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'feature/FOO-76'
        Initialize-BranchPushed 'feature/FOO-76'
        Initialize-UpstreamBranches @{ 'feature/FOO-76' = @("feature/FOO-123","feature/XYZ-1-services") }

        Initialize-InvokeMergeFailure 'feature/FOO-123'

        { & ./git-pull-upstream.ps1 }
            | Should -Throw "Could not complete the merge."
    }

    It 'works with a remote' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'feature/FOO-76'
        Initialize-BranchPushed 'feature/FOO-76'
        Initialize-UpstreamBranches @{ 'feature/FOO-76' = @("feature/FOO-123","feature/XYZ-1-services") }

        Initialize-InvokeMergeSuccess 'origin/feature/FOO-123'
        Initialize-InvokeMergeSuccess 'origin/feature/XYZ-1-services'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin HEAD:feature/FOO-76' } { $Global:LASTEXITCODE = 0 }

        & ./git-pull-upstream.ps1
    }

    It 'ensures the remote is up-to-date' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'feature/FOO-76'
        Initialize-BranchNotPushed 'feature/FOO-76'

        { & ./git-pull-upstream.ps1 }
            | Should -Throw "Branch feature/FOO-76 has changes not pushed to origin/feature/FOO-76. Please ensure changes are pushed (or reset) and try again."
    }

    It 'ensures the remote is tracked' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'feature/FOO-76'
        Initialize-BranchNoUpstream 'feature/FOO-76'

        { & ./git-pull-upstream.ps1 }
            | Should -Throw "Branch feature/FOO-76 does not have a remote tracking branch. Please ensure changes are pushed (or reset) and try again."
    }
}
