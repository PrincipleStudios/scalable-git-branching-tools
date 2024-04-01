Describe 'git-add-upstream' {
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

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }

        It 'halts if no branch was provided and none is checked out' {
            $mocks = @(
                Initialize-NoCurrentBranch
            )

            { & ./git-add-upstream.ps1 -upstream 'feature/FOO-76' } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Contain "ERR:  No branch name was provided"
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'works on the current branch' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-CurrentBranch 'rc/2022-07-14'
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 'feature/FOO-76'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'works if there are no upstream branches' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-CurrentBranch 'rc/2022-07-14'
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76") `
                    -to @("feature/FOO-76")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 'feature/FOO-76'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'works locally with multiple branches' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76', 'feature/FOO-84') -shouldExist $true
                Initialize-CurrentBranch 'rc/2022-07-14'
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76", 'feature/FOO-84', "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("feature/FOO-76", 'feature/FOO-84', "feature/FOO-123", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76", 'feature/FOO-84', "feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76', 'feature/FOO-84') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -m ""
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'works locally against a target branch' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-NoCurrentBranch
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 -upstream 'feature/FOO-76' -target 'rc/2022-07-14' -m ""
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'works locally with multiple branches against a target branch' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76', 'feature/FOO-84') -shouldExist $true
                Initialize-NoCurrentBranch
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76", 'feature/FOO-84', "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("feature/FOO-76", 'feature/FOO-84', "feature/FOO-123", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76", 'feature/FOO-84', "feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76', 'feature/FOO-84') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -target 'rc/2022-07-14' -m ""
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
        }

        It 'works on the current branch' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-CurrentBranch 'rc/2022-07-14'
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-LocalActionAssertPushedSuccess 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 @('feature/FOO-76') -m ""
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'works if there are no upstream branches' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-CurrentBranch 'rc/2022-07-14'
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-LocalActionAssertPushedSuccess 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76") `
                    -to @("feature/FOO-76")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 'feature/FOO-76'
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'does nothing if the added branch is already included' {
            $mocks = @(
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'infra/shared') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services","infra/shared") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("infra/shared", "infra/shared", "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("infra/shared", "feature/FOO-123", "feature/XYZ-1-services")
            )

            { & ./git-add-upstream.ps1 @('infra/shared') -target 'rc/2022-07-14' } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  No branches would be added.')
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'simplifies if the added branch makes another redundant' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-123') -shouldExist $true
                Initialize-CurrentBranch 'my-branch'
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-LocalActionAssertPushedSuccess 'rc/2022-07-14'
                Initialize-UpstreamBranches @{
                    'rc/2022-07-14' = @("infra/shared","feature/XYZ-1-services")
                    'feature/FOO-123' = @('infra/shared')
                    'infra/shared' = @('main')
                    'feature/XYZ-1-services' = @()
                    'main' = @()
                }
                Initialize-LocalActionSimplifyUpstreamBranches `
                    -from @("feature/FOO-123", "infra/shared", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-123') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 @('feature/FOO-123') -target 'rc/2022-07-14' -m ""
            $fw.assertDiagnosticOutput | Should -Be @("WARN: Removing 'infra/shared' from branches; it is redundant via the following: feature/FOO-123")
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'handles when the target branch doesn''t exist locally' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-CurrentBranch 'rc/2022-07-14'
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-LocalActionAssertPushedNotTracked 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('feature/FOO-76') -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 @('feature/FOO-76') -target 'rc/2022-07-14' -m ""
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'outputs a helpful message if it fails' {
            $mocks = @(
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-CurrentBranch 'rc/2022-07-14'
                Initialize-LocalActionAssertPushedSuccess 'rc/2022-07-14'
                Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
                Initialize-LocalActionSimplifyUpstreamBranchesSuccess `
                    -from @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services") `
                    -to @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                Initialize-LocalActionSetUpstream @{
                    'rc/2022-07-14' = @("feature/FOO-76", "feature/FOO-123", "feature/XYZ-1-services")
                } -commitish 'new-commit'
                Initialize-LocalActionMergeBranchesFailure `
                    -upstreamBranches @('feature/FOO-76') `
                    -failures @('feature/FOO-76') `
                    -resultCommitish 'result-commitish' `
                    -source 'rc/2022-07-14' `
                    -mergeMessageTemplate "Merge '{}' to rc/2022-07-14"
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                    'rc/2022-07-14' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('rc/2022-07-14')
            )

            & ./git-add-upstream.ps1 'feature/FOO-76' -m ""
            $fw.assertDiagnosticOutput | Should -Be @('WARN: rc/2022-07-14 has incoming conflicts from feature/FOO-76. Be sure to manually merge.')
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'ensures the remote is up-to-date' {
            $mocks = @(
                Initialize-AssertValidBranchName 'rc/2022-07-14'
                Initialize-LocalActionAssertExistence -branches @('rc/2022-07-14', 'feature/FOO-76') -shouldExist $true
                Initialize-LocalActionAssertPushedAhead 'rc/2022-07-14'
            )

            { & ./git-add-upstream.ps1 @('feature/FOO-76') -target 'rc/2022-07-14' -m "" } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  The local branch for rc/2022-07-14 has changes that are not pushed to the remote')
            Invoke-VerifyMock $mocks -Times 1
        }
    }

}
