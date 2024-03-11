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
        
        # These are all valid branch names; tehy don't need to be defined each time:
        Initialize-AssertValidBranchName 'integrate/FOO-100_XYZ-1'
        Initialize-AssertValidBranchName 'integrate/FOO-123_XYZ-1'
        Initialize-AssertValidBranchName 'feature/FOO-100'
        Initialize-AssertValidBranchName 'feature/FOO-123'
        Initialize-AssertValidBranchName 'feature/FOO-124'
        Initialize-AssertValidBranchName 'feature/FOO-125'
        Initialize-AssertValidBranchName 'feature/XYZ-1-services'
        Initialize-AssertValidBranchName 'main'
    }

    It 'prevents running if neither remove nor rename are provided' {
        { & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-123' -target 'main' } | Should -Throw

        $fw.assertDiagnosticOutput | Should -Contain 'ERR:  Either -rename or -remove must be specfied.'
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'prevents running if both remove and rename are provided' {
        { & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-123' -target 'main' -remove -rename } | Should -Throw

        $fw.assertDiagnosticOutput | Should -Contain 'ERR:  Only one of -rename and -remove may be specified.'
        Invoke-VerifyMock $mocks -Times 1
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
            Initialize-LocalActionSetUpstream @{
                'feature/FOO-123' = $null
                'integrate/FOO-123_XYZ-1' = @("feature/XYZ-1-services")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                _upstream = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-123' -target 'main' -remove

        $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'main' from upstream branches of 'integrate/FOO-123_XYZ-1'; it is redundant via the following: feature/XYZ-1-services"
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

    It 'can rename an incorrectly named branch already used correctly sometimes' {
        $mocks = @(
            Initialize-AllUpstreamBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-100", "feature/XYZ-1-services")
                'feature/FOO-124' = @("feature/FOO-123", "main")
                'feature/FOO-100' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
            }
            Initialize-LocalActionSetUpstream @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-100' = @()
                'feature/FOO-123' = @('main')
                'feature/FOO-124' = @("feature/FOO-123")
            } -commitish 'new-commit'
            Initialize-FinalizeActionSetBranches @{
                _upstream = 'new-commit'
            }
        )

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-100' -target 'feature/FOO-123' -rename
        
        $fw.assertDiagnosticOutput | Should -Be @(
            "WARN: Removing 'main' from upstream branches of 'feature/FOO-124'; it is redundant via the following: feature/FOO-123"
        )
        Invoke-VerifyMock $mocks -Times 1
    }

    Describe 'Advanced use-cases' {
        It 'simplifies other downstream branches' {
            $mocks = @(
                Initialize-AllUpstreamBranches @{
                    'feature/FOO-125' = @("feature/FOO-124", "main")
                    'feature/FOO-124' = @("feature/FOO-123")
                }
                Initialize-LocalActionSetUpstream @{
                    'feature/FOO-123' = $null
                    'feature/FOO-124' = @("main")
                    'feature/FOO-125' = @("feature/FOO-124")
                } -commitish 'new-commit'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                }
            )

            & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-123' -target 'main' -remove
            
            $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'main' from upstream branches of 'feature/FOO-125'; it is redundant via the following: feature/FOO-124"
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'does not create repeat upstreams' {
            $mocks = @(
                Initialize-AllUpstreamBranches @{
                    'feature/FOO-123' = @("main")
                    'feature/FOO-124' = @("feature/FOO-123", "main")
                }
                Initialize-LocalActionSetUpstream @{
                    'feature/FOO-123' = $null
                    'feature/FOO-124' = @("main")
                } -commitish 'new-commit'
                Initialize-FinalizeActionSetBranches @{
                    _upstream = 'new-commit'
                }
            )

            & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-123' -target 'main' -remove
            
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
