BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/input/Assert-ValidBranchName.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
    Initialize-QuietMergeBranches
}

Describe 'git-new' {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework -throwInsteadOfExit
    }
    
    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Lock-LocalActionSetUpstream

            Initialize-AnyUpstreamBranches
        }

        It 'halts if the working directory is not clean' {
            Initialize-DirtyWorkingDirectory

            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-LocalActionSetUpstream @{
                'feature/PS-100-some-work' = 'main'
            } -commitish 'new-commit'
            
            { & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work' } | Should -Throw 'ERR:  Git working directory is not clean.'
            $fw.assertDiagnosticOutput | Should -Contain 'ERR:  Git working directory is not clean.'
        }

        It 'handles standard functionality' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'

            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-100-some-work' = 'main'
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-100-some-work' `
                    @('main') 'latest-main'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'feature/PS-100-some-work' = 'latest-main'
                }
                Initialize-FinalizeActionCheckout 'feature/PS-100-some-work'
            )

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'creates a local branch when no remotes are configured' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-100-some-work' = 'main'
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-100-some-work' `
                    @('main') 'latest-main'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'feature/PS-100-some-work' = 'latest-main'
                }
                Initialize-FinalizeActionCheckout 'feature/PS-100-some-work'
            )

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'creates a local branch from the specified branch when no remotes are configured' {
            Initialize-AssertValidBranchName 'feature/PS-600-some-work'
            Initialize-AssertValidBranchName 'infra/foo'

            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-600-some-work' = 'infra/foo'
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-600-some-work' `
                    @('infra/foo') 'latest-foo'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'feature/PS-600-some-work' = 'latest-foo'
                }
                Initialize-FinalizeActionCheckout 'feature/PS-600-some-work'
            )

            & $PSScriptRoot/git-new.ps1 feature/PS-600-some-work -u 'infra/foo' -m 'some work'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-CleanWorkingDirectory

            Initialize-AnyUpstreamBranches
            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/foo')
                'infra/foo' = @('main')
            }
            Lock-LocalActionSetUpstream
        }

        It 'detects an invalid branch name and prevents moving forward' {
            Initialize-AssertInvalidBranchName 'feature/PS-100-some-work'
            
            { & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work' } | Should -Throw

            $fw.assertDiagnosticOutput | Should -Be @(
                "ERR:  Invalid branch name specified: 'feature/PS-100-some-work'"
            )
        }

        It 'creates a remote branch when a remote is configured' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'

            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-100-some-work' = 'main'
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-100-some-work' `
                    @('main') 'latest-main'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'feature/PS-100-some-work' = 'latest-main'
                }
                Initialize-FinalizeActionCheckout 'feature/PS-100-some-work'
            )

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
            Invoke-VerifyMock $mocks -Times 1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'creates a remote branch when a remote is configured and an upstream branch is provided' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'infra/foo'

            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-100-some-work' = 'infra/foo'
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-100-some-work' `
                    @('infra/foo') 'latest-foo'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'feature/PS-100-some-work' = 'latest-foo'
                }
                Initialize-FinalizeActionCheckout 'feature/PS-100-some-work'
            )

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'infra/foo' -m 'some work'
            Invoke-VerifyMock $mocks -Times 1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'creates a remote branch with simplified upstream dependencies' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'infra/foo'
            Initialize-AssertValidBranchName 'main'
            Initialize-AssertValidBranchName 'feature/homepage-redesign'
            
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-100-some-work' = @('feature/homepage-redesign')
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-100-some-work' `
                    @('feature/homepage-redesign') 'latest-redesign'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'feature/PS-100-some-work' = 'latest-redesign'
                }
                Initialize-FinalizeActionCheckout 'feature/PS-100-some-work'
            )

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'infra/foo,main,feature/homepage-redesign' -m 'some work'
            Invoke-VerifyMock $mocks -Times 1
            $fw.assertDiagnosticOutput | Should -Be @(
                "WARN: Removing 'infra/foo' from branches; it is redundant via the following: feature/homepage-redesign"
                "WARN: Removing 'main' from branches; it is redundant via the following: feature/homepage-redesign"
            )
        }

        It 'creates a remote branch with simplified upstream dependencies but still multiple' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'infra/foo'
            Initialize-AssertValidBranchName 'main'
            Initialize-AssertValidBranchName 'feature/homepage-redesign'
            Initialize-AssertValidBranchName 'infra/update-dependencies'
            
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-100-some-work' = @('feature/homepage-redesign', 'infra/update-dependencies')
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-100-some-work' `
                    @('feature/homepage-redesign', 'infra/update-dependencies') 'merge-result'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'feature/PS-100-some-work' = 'merge-result'
                }
                Initialize-FinalizeActionCheckout 'feature/PS-100-some-work'
            )

            & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'infra/foo,main,feature/homepage-redesign,infra/update-dependencies' -m 'some work'
            Invoke-VerifyMock $mocks -Times 1
            $fw.assertDiagnosticOutput | Should -Be @(
                "WARN: Removing 'infra/foo' from branches; it is redundant via the following: feature/homepage-redesign"
                "WARN: Removing 'main' from branches; it is redundant via the following: feature/homepage-redesign"
            )
        }

        It 'reports failed merges and does not push' {
            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            Initialize-AssertValidBranchName 'feature/homepage-redesign'
            Initialize-AssertValidBranchName 'infra/update-dependencies'
            
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'feature/PS-100-some-work' = @('feature/homepage-redesign', 'infra/update-dependencies')
                } -commitish 'new-commit'
                Initialize-LocalActionCreateBranchSuccess 'feature/PS-100-some-work' `
                    @('feature/homepage-redesign', 'infra/update-dependencies') 'merge-result' `
                    -failAtMerge 1
            )

            { & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'feature/homepage-redesign,infra/update-dependencies' -m 'some work' } | Should -Throw 'ERR:  Failed to merge all branches'
            $fw.assertDiagnosticOutput | Should -Contain 'ERR:  Failed to merge all branches'
            Invoke-VerifyMock $mocks -Times 1
        }
    }

}
