BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    Lock-SetMultipleUpstreamBranches
}

Describe 'git-add-upstream' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Set-RemoteTracking.mocks.psm1"
        Initialize-QuietMergeBranches
    }

    BeforeEach {
        Register-Framework
    }

    It 'works on the current branch' {
        { git branch -a } | Should -Throw -Because 'we should have locked git down'

        Initialize-ToolConfiguration -noRemote

        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'rc/2022-07-14'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'feature/FOO-76'
        Initialize-PreserveBranchCleanup

        Initialize-SetMultipleUpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
        } 'Add feature/FOO-76 to rc/2022-07-14' -commitish 'new-upstream-commit'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 'feature/FOO-76'
    }

    It 'works locally with multiple branches' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'rc/2022-07-14'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        $merge1Filter = Initialize-InvokeMergeSuccess 'feature/FOO-76'
        $merge2Filter = Initialize-InvokeMergeSuccess 'feature/FOO-84'
        Initialize-PreserveBranchCleanup

        Initialize-SetMultipleUpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-84", "feature/FOO-123", "feature/XYZ-1-services")
        } 'Add feature/FOO-76, feature/FOO-84 to rc/2022-07-14' -commitish 'new-upstream-commit'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -m ""

        Invoke-VerifyMock $merge1Filter -Times 1
        Invoke-VerifyMock $merge2Filter -Times 1
    }

    It 'works locally against a target branch' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'feature/FOO-76'
        Initialize-PreserveBranchCleanup

        Initialize-SetMultipleUpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
        } 'Add feature/FOO-76 to rc/2022-07-14' -commitish 'new-upstream-commit'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 -upstream 'feature/FOO-76' -target 'rc/2022-07-14' -m ""
    }

    It 'works locally with multiple branches against a target branch' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        $merge1Filter = Initialize-InvokeMergeSuccess 'feature/FOO-76'
        $merge2Filter = Initialize-InvokeMergeSuccess 'feature/FOO-84'
        Initialize-PreserveBranchCleanup

        Initialize-SetMultipleUpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-84", "feature/FOO-123", "feature/XYZ-1-services")
        } 'Add feature/FOO-76, feature/FOO-84 to rc/2022-07-14' -commitish 'new-upstream-commit'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -target 'rc/2022-07-14' -m ""

        Invoke-VerifyMock $merge1Filter -Times 1
        Invoke-VerifyMock $merge2Filter -Times 1
    }

    It 'works with a remote' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchPushed 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-76'
        Initialize-PreserveBranchCleanup

        Initialize-SetMultipleUpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
        } 'Add feature/FOO-76 to rc/2022-07-14' -commitish 'new-upstream-commit'
        Initialize-SetRemoteTracking 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic HEAD:rc/2022-07-14 new-upstream-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 @('feature/FOO-76') -target 'rc/2022-07-14' -m ""
    }

    It 'does nothing if the added branch is already included' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
            'feature/FOO-123' = @('infra/shared')
            'feature/XYZ-1-services' = @('infra/shared')
        }
        Initialize-BranchPushed 'rc/2022-07-14'

        { & ./git-add-upstream.ps1 @('infra/shared') -target 'rc/2022-07-14' } | Should -Throw 'All branches already upstream of target branch'
    }

    It 'simplifies if the added branch makes another redundant' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{
            'rc/2022-07-14' = @("infra/shared","feature/XYZ-1-services")
            'feature/FOO-123' = @('infra/shared')
        }
        Initialize-BranchPushed 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-123'
        Initialize-PreserveBranchCleanup

        Initialize-SetMultipleUpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-123", "feature/XYZ-1-services")
        } -commitish 'new-upstream-commit'
        Initialize-SetRemoteTracking 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic HEAD:rc/2022-07-14 new-upstream-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 @('feature/FOO-123') -target 'rc/2022-07-14' -m ""
    }

    It 'works with a remote when the target branch doesn''t exist locally' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchDoesNotExist 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-76'
        Initialize-PreserveBranchCleanup

        Initialize-SetMultipleUpstreamBranches @{
            'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
        } -commitish 'new-upstream-commit'
        Initialize-SetRemoteTracking 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic HEAD:rc/2022-07-14 new-upstream-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 @('feature/FOO-76') -target 'rc/2022-07-14' -m ""
    }

    It 'outputs a helpful message if it fails' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'rc/2022-07-14'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchPushed 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeFailure 'feature/FOO-76'
        $mocks = Initialize-PreserveBranchCleanup

        & ./git-add-upstream.ps1 'feature/FOO-76' -m ""

        $LASTEXITCODE | Should -Be 1

        Should -Invoke -CommandName Write-Host -Times 1 -ParameterFilter { $Object -ne $nil -and $Object[0] -match 'git merge feature/FOO-76' }
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'ensures the remote is up-to-date' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchNotPushed 'rc/2022-07-14'

        { & ./git-add-upstream.ps1 @('feature/FOO-76') -target 'rc/2022-07-14' -m "" }
            | Should -Throw "Branch rc/2022-07-14 has changes not pushed to origin/rc/2022-07-14. Please ensure changes are pushed (or reset) and try again."
    }

    It 'ensures the remote is tracked' {
        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-AnyUpstreamBranches
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchNoUpstream 'rc/2022-07-14'

        { & ./git-add-upstream.ps1 @('feature/FOO-76') -target 'rc/2022-07-14' -m "" }
            | Should -Throw "Branch rc/2022-07-14 does not have a remote tracking branch. Please ensure changes are pushed (or reset) and try again."
    }

}
