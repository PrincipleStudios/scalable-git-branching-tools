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

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $initialCommits = @{
            'rc/2022-07-14' = 'rc/2022-07-14-commitish'
            'main' = 'main-commitish'
            'feature/FOO-123' = 'feature/FOO-123-commitish'
            'feature/XYZ-1-services' = 'feature/XYZ-1-services-commitish'
            'feature/FOO-124-comment' = 'feature/FOO-124-comment-commitish'
            'feature/FOO-124_FOO-125' = 'feature/FOO-124_FOO-125-commitish'
            'feature/FOO-76' = 'feature/FOO-76-commitish'
            'integrate/FOO-125_XYZ-1' = 'integrate/FOO-125_XYZ-1-commitish'
        }
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
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/XYZ-1-services' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/FOO-123' -initialCommits $initialCommits
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
                'main' = $initialCommits['rc/2022-07-14']
                'feature/FOO-123' = $null
                'feature/XYZ-1-services' = $null
                'rc/2022-07-14' = $null
            }

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }
        
        It 'fails if an intermediate branch was not fully released' {
            Initialize-AllUpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedFailure 'rc/2022-07-14' 'feature/XYZ-1-services' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedFailure 'rc/2022-07-14' 'feature/FOO-123' -initialCommits $initialCommits

            { & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main } | Should -Throw
            $fw.assertDiagnosticOutput.Count | Should -Be 2
            $fw.assertDiagnosticOutput | Should -Contain 'ERR:  The branch feature/XYZ-1-services has changes that are not in rc/2022-07-14'
            $fw.assertDiagnosticOutput | Should -Contain 'ERR:  The branch feature/FOO-123 has changes that are not in rc/2022-07-14'
        }
        
        It 'allows forced removal even if a intermediate branches were not fully released' {
            Initialize-AllUpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedFailure 'rc/2022-07-14' 'main' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedFailure 'rc/2022-07-14' 'feature/XYZ-1-services' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedFailure 'rc/2022-07-14' 'feature/FOO-123' -initialCommits $initialCommits
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
                'main' = $initialCommits['rc/2022-07-14']
                'feature/FOO-123' = $null
                'feature/XYZ-1-services' = $null
                'rc/2022-07-14' = $null
            }

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -force
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
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/XYZ-1-services' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/FOO-123' -initialCommits $initialCommits
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
            Initialize-AssertValidBranchName 'feature/FOO-123'
            Initialize-AssertValidBranchName 'feature/XYZ-1-services'
            Initialize-AssertValidBranchName 'rc/2022-07-14'

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
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/FOO-124-comment' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/XYZ-1-services' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/FOO-124_FOO-125' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'integrate/FOO-125_XYZ-1' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/FOO-123' -initialCommits $initialCommits
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
                'main' = $initialCommits['rc/2022-07-14']
                'feature/FOO-123' = $null
                'integrate/FOO-125_XYZ-1' = $null
                'rc/2022-07-14' = $null
                'feature/XYZ-1-services' = $null
                'feature/FOO-124_FOO-125' = $null
                'feature/FOO-124-comment' = $null
            }

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'can preserve some branches' {
            Initialize-AllUpstreamBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = {}
                'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1")
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'main' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/FOO-124-comment' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/XYZ-1-services' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'rc/2022-07-14' 'feature/FOO-123' -initialCommits $initialCommits
            Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                -from @("feature/FOO-124_FOO-125", "main") `
                -to @("feature/FOO-124_FOO-125")
            Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                -from @("main") `
                -to @("main")
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null
                'rc/2022-07-14' = $null
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125")
                'feature/FOO-124_FOO-125' = @("main")
                'feature/FOO-124-comment' = $null
                'feature/XYZ-1-services' = $null
            } -commitMessage 'Release rc/2022-07-14 to main' -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '_upstream' = 'new-commit'
                'main' = $initialCommits['rc/2022-07-14']
                'feature/FOO-123' = $null
                'rc/2022-07-14' = $null
                'feature/FOO-124-comment' = $null
                'feature/XYZ-1-services' = $null
            }

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -preserve integrate/FOO-125_XYZ-1,feature/FOO-124_FOO-125
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
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'feature/FOO-123' 'main' -initialCommits $initialCommits
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null
            } -commitMessage 'Release feature/FOO-123 to main' -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '_upstream' = 'new-commit'
                'main' = $initialCommits['feature/FOO-123']
                'feature/FOO-123' = $null
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
            } -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'main' 'rc/2022-07-14' -initialCommits $initialCommits
            Initialize-LocalActionAssertUpdatedSuccess 'main' 'feature/XYZ-1-services' -initialCommits $initialCommits
            Initialize-LocalActionSetUpstream @{
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125")
                'rc/2022-07-14' = $null
                'feature/XYZ-1-services' = $null
            } -commitMessage 'Release rc/2022-07-14 to main' -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                '_upstream' = 'new-commit'
                'rc/2022-07-14' = $null
                'feature/XYZ-1-services' = $null
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
