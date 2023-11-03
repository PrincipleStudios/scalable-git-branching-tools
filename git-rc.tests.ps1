BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-Branches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.mocks.psm1"

    Initialize-QuietMergeBranches

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    Lock-SetMultipleUpstreamBranches

    Mock -CommandName Invoke-PreserveBranch {
        & $scriptBlock
        & $cleanup
    }
}


Describe 'git-rc' {
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
        $fw = Register-Framework -throwInsteadOfExit
    }
    
    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Initialize-UpstreamBranches  @{
                'feature/FOO-123' = @('main')
                'feature/FOO-124-comment' = @('main')
                'integrate/FOO-125_XYZ-1' = @('feature/FOO-125', 'feature/XYZ-1')
            }
            Initialize-NoCurrentBranch
        }

        It 'handles standard functionality' {
            $mocks = @(
                Initialize-AssertValidBranchName 'rc/2022-07-28'
                Initialize-AssertValidBranchName 'feature/FOO-123'
                Initialize-AssertValidBranchName 'feature/FOO-124-comment'
                Initialize-AssertValidBranchName 'integrate/FOO-125_XYZ-1'
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-28') -shouldExist $false
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                Initialize-LocalActionUpstreamsUpdated @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') -recurse
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-28' = @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                } -commitish 'new-commit' -message 'Add branch rc/2022-07-28 for New RC'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2022-07-28"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-28' = 'result-rc-commit'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-28') -untracked @('rc/2022-07-28')
            )

            & $PSScriptRoot/git-rc.ps1 -upstreamBranches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -target 'rc/2022-07-28'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-NoCurrentBranch
            Initialize-UpstreamBranches @{
                'feature/FOO-123' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-125' = @('main')
                'feature/XYZ-1' = @('main')
                'integrate/FOO-125_XYZ-1' = @('feature/FOO-125', 'feature/XYZ-1')
            }
        }

        It 'handles standard functionality' {
            $mocks = @(
                Initialize-AssertValidBranchName 'rc/2022-07-28'
                Initialize-AssertValidBranchName 'feature/FOO-123'
                Initialize-AssertValidBranchName 'feature/FOO-124-comment'
                Initialize-AssertValidBranchName 'integrate/FOO-125_XYZ-1'
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-28') -shouldExist $false
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                Initialize-LocalActionUpstreamsUpdated @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') -recurse
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-28' = @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                } -commitish 'new-commit' -message 'Add branch rc/2022-07-28 for New RC'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2022-07-28"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-28' = 'result-rc-commit'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-28') -untracked @('rc/2022-07-28')
            )

            & $PSScriptRoot/git-rc.ps1 -upstreamBranches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -target 'rc/2022-07-28'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'allows a null comment' {
            $mocks = @(
                Initialize-AssertValidBranchName 'rc/2022-07-28'
                Initialize-AssertValidBranchName 'feature/FOO-123'
                Initialize-AssertValidBranchName 'feature/FOO-124-comment'
                Initialize-AssertValidBranchName 'integrate/FOO-125_XYZ-1'
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-28') -shouldExist $false
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                Initialize-LocalActionUpstreamsUpdated @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') -recurse
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-28' = @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                } -commitish 'new-commit' -message 'Add branch rc/2022-07-28'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2022-07-28"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-28' = 'result-rc-commit'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-28') -untracked @('rc/2022-07-28')
            )

            & $PSScriptRoot/git-rc.ps1 -upstreamBranches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m $nil -target 'rc/2022-07-28'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'simplifies upstream before creating the rc' {            
            $mocks = @(
                Initialize-AssertValidBranchName 'rc/2022-07-28'
                Initialize-AssertValidBranchName 'feature/FOO-123'
                Initialize-AssertValidBranchName 'feature/FOO-125'
                Initialize-AssertValidBranchName 'feature/XYZ-1'
                Initialize-AssertValidBranchName 'integrate/FOO-125_XYZ-1'
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-28') -shouldExist $false
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-123','feature/FOO-125','feature/XYZ-1','integrate/FOO-125_XYZ-1')
                Initialize-LocalActionUpstreamsUpdated @('feature/FOO-123','integrate/FOO-125_XYZ-1') -recurse
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-28' = @('feature/FOO-123','integrate/FOO-125_XYZ-1')
                } -commitish 'new-commit' -message 'Add branch rc/2022-07-28 for New RC'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123','integrate/FOO-125_XYZ-1') 'result-rc-commit' `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2022-07-28"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-28' = 'result-rc-commit'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-28') -untracked @('rc/2022-07-28')
            )

            & $PSScriptRoot/git-rc.ps1 -upstreamBranches feature/FOO-123,feature/FOO-125,feature/XYZ-1,integrate/FOO-125_XYZ-1 -m 'New RC' -target 'rc/2022-07-28'
            $fw.assertDiagnosticOutput | Should -Be @("WARN: Removing 'feature/FOO-125' from branches; it is redundant via the following: integrate/FOO-125_XYZ-1", "WARN: Removing 'feature/XYZ-1' from branches; it is redundant via the following: integrate/FOO-125_XYZ-1")
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'does not push if there is a failure while merging' {
            $mocks = @(
                Initialize-AssertValidBranchName 'rc/2022-07-28'
                Initialize-AssertValidBranchName 'feature/FOO-123'
                Initialize-AssertValidBranchName 'feature/FOO-124-comment'
                Initialize-AssertValidBranchName 'integrate/FOO-125_XYZ-1'
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-28') -shouldExist $false
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                Initialize-LocalActionUpstreamsUpdated @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') -recurse
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-28' = @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1')
                } -commitish 'new-commit' -message 'Add branch rc/2022-07-28 for new RC'
                Initialize-LocalActionMergeBranchesSuccess `
                    @('feature/FOO-123','feature/FOO-124-comment','integrate/FOO-125_XYZ-1') 'result-rc-commit' `
                    -failedBranches @('feature/FOO-124-comment') `
                    -mergeMessageTemplate "Merge '{}' for creation of rc/2022-07-28"
            )

            { & $PSScriptRoot/git-rc.ps1 -upstreamBranches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -target 'rc/2022-07-28' } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @("ERR:  Could not merge the following branches: origin/feature/FOO-124-comment")
            Invoke-VerifyMock $mocks -Times 1
        }
    }

}
