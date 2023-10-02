BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/input/Assert-ValidBranchName.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
    Initialize-QuietMergeBranches

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    # Mock -CommandName Write-Host {}
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
            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/upgrade-dependencies')
            }
        }

        It 'halts if the working directory is not clean' {
            Initialize-DirtyWorkingDirectory

            Initialize-AssertValidBranchName 'feature/PS-100-some-work'
            $output = Register-Diagnostics -throwInsteadOfExit
            
            { & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work' } | Should -Throw
            $output | Should -Contain 'ERR:  Git working directory is not clean.'
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
            Invoke-VerifyMock $mocks -Times 1
            $fw.diagnostics | Should -Be $null
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

            $fw.diagnostics | Should -Be @(
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
            $fw.diagnostics | Should -Be $null
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
            $fw.diagnostics | Should -Be $null
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

            { & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -u 'feature/homepage-redesign,infra/update-dependencies' -m 'some work' } | Should -Throw 'Fake Exit-DueToAssert'
            # TODO - verify error messages
            # $fw.diagnostics
            Invoke-VerifyMock $mocks -Times 1
        }
    }

}
