Describe 'git-release' {
    BeforeAll {
        . "$PSScriptRoot/utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    function Add-StandardTests {
        It 'handles standard functionality' {
            Initialize-AllUpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
            }
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits @{
                'rc/2022-07-14' = 'result-commitish'
                'main' = 'old-main'
            }
            Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                -from @("feature/FOO-124_FOO-125", "main") `
                -to @("feature/FOO-124_FOO-125")
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null;
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125");
                'rc/2022-07-14' = $null;
                'feature/XYZ-1-services' = $null;
            } 'Release rc/2022-07-14 to main' 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '_upstream' = 'new-commit'
                'main' = 'result-commitish'
            }

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }
        
        It 'can issue a dry run' {
            Initialize-AllUpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
            }
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits @{
                'rc/2022-07-14' = 'result-commitish'
                'main' = 'old-main'
            }
            Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                -from @("feature/FOO-124_FOO-125", "main") `
                -to @("feature/FOO-124_FOO-125")
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null;
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125");
                'rc/2022-07-14' = $null;
                'feature/XYZ-1-services' = $null;
            } 'Release rc/2022-07-14 to main' 'new-commit'
            Initialize-AssertValidBranchName '_upstream'

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -dryRun
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'handles integration branches recursively' {
            Initialize-AllUpstreamBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = {}
                'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1")
            }
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits @{
                'rc/2022-07-14' = 'result-commitish'
                'main' = 'old-main'
            }
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null
                'integrate/FOO-125_XYZ-1' = $null
                'rc/2022-07-14' = $null
                'feature/XYZ-1-services' = $null
                'feature/FOO-124_FOO-125' = $null
                'feature/FOO-124-comment' = $null
            } -commitMessage 'Release rc/2022-07-14 to main' -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '_upstream' = 'new-commit'
                'main' = 'result-commitish'
            }

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'handles a single upstream branch' {
            Initialize-AllUpstreamBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = {}
                'rc/2022-07-14' = @("feature/XYZ-1-services")
            }
            Initialize-LocalActionAssertUpdatedSuccess 'feature/FOO-123' 'main' -initialCommits @{
                'feature/FOO-123' = 'result-commitish'
                'main' = 'old-main'
            }
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null
            } -commitMessage 'Release feature/FOO-123 to main' -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '_upstream' = 'new-commit'
                'main' = 'result-commitish'
            }

            & $PSScriptRoot/git-release.ps1 feature/FOO-123 main
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'aborts if not a fast-forward' {
            Initialize-LocalActionAssertUpdatedFailure 'rc/2022-07-14' 'main'

            { & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be 'ERR:  The branch main has changes that are not in rc/2022-07-14'
        }

        It 'can clean up if already released' {
            Initialize-AllUpstreamBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = {}
                'rc/2022-07-14' = @("feature/XYZ-1-services")
            }
            Initialize-LocalActionAssertUpdatedSuccess 'main' 'rc/2022-07-14' -initialCommits @{
                'rc/2022-07-14' = 'released-rc'
                'main' = 'result-commitish'
            }
            Initialize-LocalActionSetUpstream @{
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125")
                'rc/2022-07-14' = $null
                'feature/XYZ-1-services' = $null
            } -commitMessage 'Release rc/2022-07-14 to main' -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '_upstream' = 'new-commit'
            }
            Initialize-AssertValidBranchName 'main'
            Initialize-AssertValidBranchName 'feature/FOO-124_FOO-125'

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -cleanupOnly
            $fw.assertDiagnosticOutput | Should -Be "WARN: Removing 'main' from upstream branches of 'integrate/FOO-125_XYZ-1'; it is redundant via the following: feature/FOO-124_FOO-125"
        }

        It 'aborts clean up if not already released' {
            Initialize-LocalActionAssertUpdatedFailure 'main' 'rc/2022-07-14'

            { & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -cleanupOnly } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be 'ERR:  The branch rc/2022-07-14 has changes that are not in main'
        }
    }
    
    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-NoCurrentBranch
        }
        Add-StandardTests
    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-NoCurrentBranch
        }
        Add-StandardTests
    }
}
