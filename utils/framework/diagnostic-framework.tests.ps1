Describe 'diagnostic-framework' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/diagnostic-framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/diagnostic-framework.mocks.psm1"
    }

    Context 'when diagnostics are passed' {
        It 'records diagnostics' {
            $diag = New-Diagnostics
            Add-WarningDiagnostic $diag 'Warning 1'
            Add-ErrorDiagnostic $diag 'Error 1'
            Add-WarningDiagnostic $diag 'Warning 2'
            $output = Register-Diagnostics -throwInsteadOfExit
            { Assert-Diagnostics $diag } | Should -Throw

            $output | Should -Contain 'WARN: Warning 1'
            $output | Should -Contain 'WARN: Warning 2'
            $output | Should -Contain 'ERR:  Error 1'
        }

        It 'does not throw if there are no errors' {
            $diag = New-Diagnostics
            Add-WarningDiagnostic $diag 'Warning 1'
            Add-WarningDiagnostic $diag 'Warning 2'
            $output = Register-Diagnostics -throwInsteadOfExit
            { Assert-Diagnostics $diag } | Should -Not -Throw

            $output | Should -Be @('WARN: Warning 1', 'WARN: Warning 2')
        }

        It 'only outputs warnings once' {
            $diag = New-Diagnostics
            Add-WarningDiagnostic $diag 'Warning 1'
            Add-WarningDiagnostic $diag 'Warning 2'
            $output = Register-Diagnostics -throwInsteadOfExit
            { Assert-Diagnostics $diag } | Should -Not -Throw
            { Assert-Diagnostics $diag } | Should -Not -Throw
            
            $output | Should -Be @('WARN: Warning 1', 'WARN: Warning 2')
        }

        It 'can be empty' {
            $diag = New-Diagnostics
            $output = Register-Diagnostics -throwInsteadOfExit
            { Assert-Diagnostics $diag } | Should -Not -Throw

            $output | Should -BeNullOrEmpty
        }
        
        It 'provides an easy way to access diagnostic strings for testing' {
            $diag = New-Diagnostics
            Add-WarningDiagnostic $diag 'Warning 1'
            Add-WarningDiagnostic $diag 'Warning 2'
            $output = Get-DiagnosticStrings $diag

            $output | Should -Be @('WARN: Warning 1', 'WARN: Warning 2')
        }
    }

    Context 'when diagnostics are not passed' {
        It 'does not throw on warnings' {
            { Add-WarningDiagnostic $nil 'Warning 1' } | Should -Not -Throw
        }

        It 'throws on errors' {
            { Add-ErrorDiagnostic $nil 'Error 1' } | Should -Throw
        }
    }

}