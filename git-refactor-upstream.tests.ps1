Describe 'git-refactor-upstream' {
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

        Initialize-ToolConfiguration
        Initialize-UpdateGitRemote
    }

    It 'can consolidate a released branch (feature/FOO-123) into main' {
        $mocks = @(
            Initialize-AllUpstreamBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
                'feature/FOO-123' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-AssertValidBranchName 'feature/FOO-123'
            Initialize-AssertValidBranchName 'main'
            Initialize-LocalActionSimplifyUpstreamBranchesSuccess @('feature/XYZ-1-services', 'main') @('feature/XYZ-1-services')
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null
                'integrate/FOO-123_XYZ-1' = @("feature/XYZ-1-services")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                _upstream = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-123' -target 'main' -remove

        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can consolidate an integration branch (integrate/FOO-123_XYZ-1) into its remaining upstream' {
        $mocks = @(
            Initialize-AllUpstreamBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/XYZ-1-services")
                'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-AssertValidBranchName 'integrate/FOO-123_XYZ-1'
            Initialize-AssertValidBranchName 'feature/XYZ-1-services'
            Initialize-LocalActionSimplifyUpstreamBranchesSuccess @('feature/XYZ-1-services') @('feature/XYZ-1-services')
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-124' = @("feature/XYZ-1-services")
                'rc/1.1.0' = @("feature/XYZ-1-services")
                'integrate/FOO-123_XYZ-1' = @()
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                _upstream = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'integrate/FOO-123_XYZ-1' -target 'feature/XYZ-1-services' -remove
        
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can rename an incorrectly named branch' {
        $mocks = @(
            Initialize-AllUpstreamBranches @{
                'integrate/FOO-100_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-124' = @("integrate/FOO-100_XYZ-1")
                'feature/FOO-123' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-100_XYZ-1")
            }
            Initialize-AssertValidBranchName 'integrate/FOO-100_XYZ-1'
            Initialize-AssertValidBranchName 'integrate/FOO-123_XYZ-1'
            Initialize-LocalActionSimplifyUpstreamBranchesSuccess @('integrate/FOO-123_XYZ-1') @('integrate/FOO-123_XYZ-1')
            Initialize-LocalActionSetUpstream @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'integrate/FOO-100_XYZ-1' = @()
                'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                _upstream = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'integrate/FOO-100_XYZ-1' -target 'integrate/FOO-123_XYZ-1' -rename
        
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }
}
