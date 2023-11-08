Describe 'git-rebuild-rc' {
    BeforeAll {
        . "$PSScriptRoot/utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
        
        Function Initialize-DefaultMocks {
            Initialize-UpdateGitRemote
            Initialize-NoCurrentBranch
            Initialize-UpstreamBranches  @{
                'feature/FOO-123' = @('main')
                'feature/FOO-124-comment' = @('main')
                'integrate/FOO-125_XYZ-1' = @('feature/FOO-125', 'feature/XYZ-1')
                'feature/FOO-125' = @('main')
                'feature/XYZ-1' = @('main')
                'rc/2023-11-08' = @('feature/FOO-123', 'feature/FOO-125')
            }
            Initialize-AssertValidBranchName 'feature/FOO-123'
            Initialize-AssertValidBranchName 'feature/FOO-124-comment'
            Initialize-AssertValidBranchName 'integrate/FOO-125_XYZ-1'
            Initialize-AssertValidBranchName 'feature/FOO-125'
            Initialize-AssertValidBranchName 'feature/XYZ-1'
            Initialize-AssertValidBranchName 'rc/2023-11-08'
            Initialize-AssertValidBranchName 'main'
            Initialize-LocalActionUpstreamsUpdated @(
                'feature/FOO-123'
                'feature/FOO-124-comment'
                'integrate/FOO-125_XYZ-1'
                'feature/FOO-125'
                'feature/XYZ-1'
                'rc/2023-11-08'
                'main'
            ) -recurse

            Initialize-LocalActionAssertExistence -branches @(
                'feature/FOO-123'
                'feature/FOO-124-comment'
                'integrate/FOO-125_XYZ-1'
                'feature/FOO-125'
                'feature/XYZ-1'
                'rc/2023-11-08'
                'main'
            )
        }
    }

    Function Add-StandardTests {
        It 'can simply rebuild the branch' {
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'rc/2023-11-08' = @('feature/FOO-123', 'feature/FOO-125')
                } -commitish 'new-commit' -message 'Revise branch rc/2023-11-08'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123', 'feature/FOO-125') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2023-11-08"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2023-11-08' = 'result-rc-commit'
                } -force
                Initialize-FinalizeActionTrackSuccess @('rc/2023-11-08') -untracked @('rc/2023-11-08')
            )

            & $PSScriptRoot/git-rebuild-rc.ps1 'rc/2023-11-08'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
        
        It 'can add an upstream' {
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'rc/2023-11-08' = @('feature/FOO-123', 'feature/FOO-125', 'feature/FOO-124-comment')
                } -commitish 'new-commit' -message 'Revise branch rc/2023-11-08'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123', 'feature/FOO-125', 'feature/FOO-124-comment') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2023-11-08"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2023-11-08' = 'result-rc-commit'
                } -force
                Initialize-FinalizeActionTrackSuccess @('rc/2023-11-08') -untracked @('rc/2023-11-08')
            )

            & $PSScriptRoot/git-rebuild-rc.ps1 'rc/2023-11-08' -with 'feature/FOO-124-comment'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
        
        It 'can add an integration branch and simplify' {
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'rc/2023-11-08' = @('feature/FOO-123', 'integrate/FOO-125_XYZ-1')
                } -commitish 'new-commit' -message 'Revise branch rc/2023-11-08'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123', 'integrate/FOO-125_XYZ-1') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2023-11-08"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2023-11-08' = 'result-rc-commit'
                } -force
                Initialize-FinalizeActionTrackSuccess @('rc/2023-11-08') -untracked @('rc/2023-11-08')
            )

            & $PSScriptRoot/git-rebuild-rc.ps1 'rc/2023-11-08' -with 'integrate/FOO-125_XYZ-1'
            $fw.assertDiagnosticOutput | Should -Be "WARN: Removing 'feature/FOO-125' from branches; it is redundant via the following: integrate/FOO-125_XYZ-1"
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'can remove a branch' {
            $mocks = @(
                Initialize-LocalActionSetUpstream @{
                    'rc/2023-11-08' = @('feature/FOO-125')
                } -commitish 'new-commit' -message 'Revise branch rc/2023-11-08'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-125') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2023-11-08"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2023-11-08' = 'result-rc-commit'
                } -force
                Initialize-FinalizeActionTrackSuccess @('rc/2023-11-08') -untracked @('rc/2023-11-08')
            )

            & $PSScriptRoot/git-rebuild-rc.ps1 'rc/2023-11-08' -without 'feature/FOO-123'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-DefaultMocks
        }

        Add-StandardTests
    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-DefaultMocks
        }

        Add-StandardTests
    }
}