BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/diagnostics/diagnostic-framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/input/Assert-ValidBranchName.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-WriteTree.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.mocks.psm1";
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Set-RemoteTracking.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.mocks.psm1"
    Initialize-QuietMergeBranches

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    Mock -CommandName Invoke-PreserveBranch -ParameterFilter { $onlyIfError } {
        & $scriptBlock
    }

    Lock-InvokeWriteTree
}

Describe 'git-new' {
    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Lock-SetMultipleUpstreamBranches

            Initialize-AnyUpstreamBranches
            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/upgrade-dependencies')
            }
        }

        It 'handles standard functionality' {
            Initialize-CleanWorkingDirectory

            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch' } {
                Write-Output 'main'
            }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'clean -n' } {}
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-100-some-work' = 'main'
            } 'Add branch feature/PS-100-some-work for some work' -commitish 'new-commit'
            Initialize-CreateBranch 'feature/PS-100-some-work' 'main'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-commit --quiet' } { $Global:LASTEXITCODE = 0 }
            Initialize-CheckoutBranch 'feature/PS-100-some-work'

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
        }

        It 'creates a local branch when no remotes are configured' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-100-some-work' = 'main'
            } -commitish 'new-commit'
            Initialize-CleanWorkingDirectory
            Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'main'
            Initialize-CheckoutBranch 'feature/PS-100-some-work'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-commit --quiet' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
        }

        It 'creates a local branch from the specified branch when no remotes are configured' {
            Initialize-AssertValidBranchName 'feature/PS-600-some-work'
            Initialize-AssertValidBranchName 'infra/foo'
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-600-some-work' = 'infra/foo'
            } -commitish 'new-commit'
            Initialize-CleanWorkingDirectory
            Initialize-CreateBranch -branchName 'feature/PS-600-some-work' -source 'infra/foo'
            Initialize-CheckoutBranch 'feature/PS-600-some-work'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-commit --quiet' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-new.ps1 feature/PS-600-some-work -u 'infra/foo' -m 'some work'
        }
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-UpdateGit
            Initialize-CleanWorkingDirectory

            Initialize-AnyUpstreamBranches
            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/foo')
                'infra/foo' = @('main')
            }
            Lock-SetMultipleUpstreamBranches
        }

        It 'detects an invalid branch name and prevents moving forward' {
            Initialize-AssertInvalidBranchName 'feature/PS-100-some-work'
            $diagnostics = Register-Diagnostics
            
            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'

            $diagnostics | Should -Be @(
                "ERR:  Invalid branch name specified: 'feature/PS-100-some-work'"
            )
        }

        It 'creates a remote branch when a remote is configured' {
            $diagnostics = Register-Diagnostics
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-100-some-work' = 'main'
            } -commitish 'new-commit'
            Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'origin/main'
            Initialize-CheckoutBranch 'feature/PS-100-some-work'
            $verifySetRemoteTracking = Initialize-SetRemoteTracking 'feature/PS-100-some-work'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic feature/PS-100-some-work:refs/heads/feature/PS-100-some-work new-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
            Invoke-VerifyMock $verifySetRemoteTracking -Times 1
            $diagnostics | Should -Be $nil
        }

        It 'creates a remote branch when a remote is configured and an upstream branch is provided' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'infra/foo'
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-100-some-work' = 'infra/foo'
            } -commitish 'new-commit'
            Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'origin/infra/foo'
            Initialize-CheckoutBranch 'feature/PS-100-some-work'
            $verifySetRemoteTracking = Initialize-SetRemoteTracking 'feature/PS-100-some-work'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic feature/PS-100-some-work:refs/heads/feature/PS-100-some-work new-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'infra/foo' -m 'some work'
            Invoke-VerifyMock $verifySetRemoteTracking -Times 1
        }

        It 'creates a remote branch with simplified upstream dependencies' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'infra/foo'
            Initialize-AssertValidBranchName 'main'
            Initialize-AssertValidBranchName 'feature/homepage-redesign'
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-100-some-work' = 'feature/homepage-redesign'
            } -commitish 'new-commit'
            Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'origin/feature/homepage-redesign'
            Initialize-CheckoutBranch 'feature/PS-100-some-work'
            $verifySetRemoteTracking = Initialize-SetRemoteTracking 'feature/PS-100-some-work'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic feature/PS-100-some-work:refs/heads/feature/PS-100-some-work new-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'infra/foo,main,feature/homepage-redesign' -m 'some work'
            Invoke-VerifyMock $verifySetRemoteTracking -Times 1
        }

        It 'creates a remote branch with simplified upstream dependencies but still multiple' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'infra/foo'
            Initialize-AssertValidBranchName 'main'
            Initialize-AssertValidBranchName 'feature/homepage-redesign'
            Initialize-AssertValidBranchName 'infra/update-dependencies'
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-100-some-work' = @('feature/homepage-redesign', 'infra/update-dependencies')
            } -commitish 'new-commit'
            Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'origin/feature/homepage-redesign'
            Initialize-InvokeMergeSuccess 'origin/infra/update-dependencies'
            Initialize-CheckoutBranch 'feature/PS-100-some-work'
            $verifySetRemoteTracking = Initialize-SetRemoteTracking 'feature/PS-100-some-work'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic feature/PS-100-some-work:refs/heads/feature/PS-100-some-work new-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'infra/foo,main,feature/homepage-redesign,infra/update-dependencies' -m 'some work'
            Invoke-VerifyMock $verifySetRemoteTracking -Times 1
        }

        It 'reports failed merges and does not push' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'feature/homepage-redesign'
            Initialize-AssertValidBranchName 'infra/update-dependencies'
            Initialize-SetMultipleUpstreamBranches @{
                'feature/PS-100-some-work' = @('feature/homepage-redesign', 'infra/update-dependencies')
            } -commitish 'new-commit'
            Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'origin/feature/homepage-redesign'
            Initialize-CheckoutBranch 'feature/PS-100-some-work'
            Initialize-InvokeMergeFailure 'origin/infra/update-dependencies'

            { & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'feature/homepage-redesign,infra/update-dependencies' -m 'some work' } | Should -Throw 'Could not complete the merge.'
        }
    }

}
