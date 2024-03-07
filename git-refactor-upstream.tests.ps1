Describe 'git-refactor-upstream' {
    BeforeAll {
        . "$PSScriptRoot/utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
    }

    BeforeEach {
        Initialize-ToolConfiguration
    }

    It 'can consolidate a released branch (feature/FOO-123) into main' {
        Initialize-AllUpstreamBranches @{
            'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
            'feature/FOO-123' = @("main")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
        }

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'feature/FOO-123' -target 'main' -remove

        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        # Invoke-VerifyMock $mocks -Times 1
    } -Pending

    It 'can consolidate an integration branch (integrate/FOO-123_XYZ-1) into its remaining upstream' {
        Initialize-AllUpstreamBranches @{
            'integrate/FOO-123_XYZ-1' = @("feature/XYZ-1-services")
            'feature/FOO-124' = @("integrate/FOO-123_XYZ-1")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
        }

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'integrate/FOO-123_XYZ-1' -target 'feature/XYZ-1-services' -remove
        
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        # Invoke-VerifyMock $mocks -Times 1
    } -Pending

    It 'can rename an incorrectly named branch' {
        Initialize-AllUpstreamBranches @{
            'integrate/FOO-100_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-124' = @("integrate/FOO-100_XYZ-1")
            'feature/FOO-123' = @("main")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("integrate/FOO-100_XYZ-1")
        }

        & $PSScriptRoot/git-refactor-upstream.ps1 -source 'integrate/FOO-100_XYZ-1' -target 'integrate/FOO-123_XYZ-1' -rename
        
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        # Invoke-VerifyMock $mocks -Times 1
    } -Pending
}
