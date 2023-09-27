BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/Compress-UpstreamBranches.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-UpstreamBranches.mocks.psm1"
}

Describe 'Compress-UpstreamBranches' {
    BeforeAll {
        Initialize-ToolConfiguration
        Initialize-UpstreamBranches @{
            'my-branch' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-123' = @('main')
            'feature/XYZ-1-services' = @('main')
            'main' = @()

            # These are bad examples - they shouldn't happen!
            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }
    }

    BeforeEach {
        Register-Framework
    }

    It 'can handle a flat string' {
        Compress-UpstreamBranches my-branch | Should -Be @( 'my-branch' )
    }

    It 'does not reduce any if none can be reduced' {
        Compress-UpstreamBranches @("feature/FOO-123", "feature/XYZ-1-services") | Should -Be @("feature/FOO-123", "feature/XYZ-1-services")
    }

    It 'reduces redundant branches' {
        Compress-UpstreamBranches @("my-branch", "feature/XYZ-1-services") | Should -Be @("my-branch")
    }

    It 'allows an empty list' {
        Compress-UpstreamBranches @() | Should -Be @()
    }

    It 'does not eliminate all recursive branches' {
        Compress-UpstreamBranches @('bad-recursive-branch-1', 'bad-recursive-branch-2') | Should -Be @('bad-recursive-branch-2')
    }

    Context 'with diagnostics' {
        BeforeEach {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $diag = New-Diagnostics
        }
        
        It 'can handle a flat string' {
            Compress-UpstreamBranches my-branch $diag | Should -Be @( 'my-branch' )
            Should -ActualValue (Get-DiagnosticStrings $diag) -Be @()
        }

        It 'does not reduce any if none can be reduced' {
            Compress-UpstreamBranches @("feature/FOO-123", "feature/XYZ-1-services") $diag | Should -Be @("feature/FOO-123", "feature/XYZ-1-services")
            Should -ActualValue (Get-DiagnosticStrings $diag) -Be @()
        }

        It 'reduces redundant branches' {
            Compress-UpstreamBranches @("my-branch", "feature/XYZ-1-services") $diag | Should -Be @("my-branch")
            Should -ActualValue (Get-DiagnosticStrings $diag) -Be @("WARN: Removing 'feature/XYZ-1-services' from branches; it is redundant via the following: my-branch")
        }

        It 'allows an empty list' {
            Compress-UpstreamBranches @() $diag | Should -Be @()
            Should -ActualValue (Get-DiagnosticStrings $diag) -Be @()
        }

        It 'does not eliminate all recursive branches' {
            Compress-UpstreamBranches @('bad-recursive-branch-1', 'bad-recursive-branch-2') $diag | Should -Be @('bad-recursive-branch-2')
            Should -ActualValue (Get-DiagnosticStrings $diag) -Be @("WARN: Removing 'bad-recursive-branch-1' from branches; it is redundant via the following: bad-recursive-branch-2")
        }

    }
}
