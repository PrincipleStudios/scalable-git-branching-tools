BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
}

Describe 'git-pull-upstream' {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    function Add-StandardTests {
        It 'fails if no branch is checked out and none is specified' {
            $mocks = @(
                Initialize-NoCurrentBranch
            )

            { & ./git-pull-upstream.ps1 } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Contain "ERR:  No branch name was provided"
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'fails if the working directory is not clean' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-123'
                Initialize-CurrentBranch 'feature/FOO-123'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-123') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/FOO-123'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('infra/add-services') -resultCommitish 'result-commitish' `
                    -source 'feature/FOO-123' `
                    -mergeMessageTemplate "Merge '{}' to feature/FOO-123"
                Initialize-FinalizeActionSetBranches @{
                    'feature/FOO-123' = 'result-commitish'
                } -currentBranchDirty
                Initialize-FinalizeActionTrackSuccess @('feature/FOO-123') -currentBranchDirty
            )

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  Git working directory is not clean.')
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'merges all upstream branches for the current branch' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-CurrentBranch 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/FOO-456'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('infra/add-services', 'infra/refactor-api') -resultCommitish 'result-commitish' `
                    -source 'feature/FOO-456' `
                    -mergeMessageTemplate "Merge '{}' to feature/FOO-456"
                Initialize-FinalizeActionSetBranches @{
                    'feature/FOO-456' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('feature/FOO-456')
            )

            & $PSScriptRoot/git-pull-upstream.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It "merges upstream branches for the specified branch when an upstream branch cannot be merged" {
            $remote = $(Get-Configuration).remote
            $remotePrefix = $remote ? "$remote/" : ""

            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-CurrentBranch 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/FOO-456'
                Initialize-LocalActionMergeBranchesSuccess `
                    -upstreamBranches @('infra/add-services', 'infra/refactor-api') -resultCommitish 'result-commitish' `
                    -failedBranches 'infra/refactor-api' `
                    -source 'feature/FOO-456' `
                    -mergeMessageTemplate "Merge '{}' to feature/FOO-456"
                Initialize-FinalizeActionSetBranches @{
                    'feature/FOO-456' = 'result-commitish'
                }
                Initialize-FinalizeActionTrackSuccess @('feature/FOO-456')
            )

            & $PSScriptRoot/git-pull-upstream.ps1
            $fw.assertDiagnosticOutput | Should -Be @(
                "WARN: Could not merge the following branches: $($remotePrefix)infra/refactor-api"
            )
            Invoke-VerifyMock $mocks -Times 1
        }

    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-UpstreamBranches @{
                'feature/FOO-456' = @("infra/add-services", "infra/refactor-api")
                'feature/FOO-123' = @("infra/add-services")
                'infra/add-services' = @("main")
                'infra/refactor-api' = @("main")
            }
        }

        Add-StandardTests

        It 'ensures the remote is up-to-date' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-CurrentBranch 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedAhead 'feature/FOO-456'
            )

            { & $PSScriptRoot/git-pull-upstream.ps1 } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  The local branch for feature/FOO-456 has changes that are not pushed to the remote')
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'ensures the remote is up-to-date with the specified branch' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/FOO-456'
                Initialize-LocalActionAssertExistence -branches @('feature/FOO-456') -shouldExist $true
                Initialize-LocalActionAssertPushedAhead 'feature/FOO-456'
            )

            { & $PSScriptRoot/git-pull-upstream.ps1 'feature/FOO-456' } | Should -Throw
            $fw.assertDiagnosticOutput | Should -Be @('ERR:  The local branch for feature/FOO-456 has changes that are not pushed to the remote')
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-UpdateGitRemote
            Initialize-UpstreamBranches @{
                'feature/FOO-456' = @("infra/add-services", "infra/refactor-api")
                'feature/FOO-123' = @("infra/add-services")
                'infra/add-services' = @("main")
                'infra/refactor-api' = @("main")
            }
        }

        Add-StandardTests
    }
}
