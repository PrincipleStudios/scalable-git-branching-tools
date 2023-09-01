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

            $output | Should -Contain 'WARN: Warning 1'
            $output | Should -Contain 'WARN: Warning 2'
        }

        It 'can be empty' {
            $diag = New-Diagnostics
            $output = Register-Diagnostics -throwInsteadOfExit
            { Assert-Diagnostics $diag } | Should -Not -Throw

            $output | Should -BeNullOrEmpty
        }
    }

    Context 'when diagnostics are not passed' {
        It 'throws on warnings' {
            { Add-WarningDiagnostic $nil 'Warning 1' } | Should -Throw
        }

        It 'throws on errors' {
            { Add-ErrorDiagnostic $nil 'Error 1' } | Should -Throw
        }
    }

}