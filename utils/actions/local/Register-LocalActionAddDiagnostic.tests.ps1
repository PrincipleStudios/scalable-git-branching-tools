Describe 'local action "add-diagnostic"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    It 'sends custom error messages by default' {
        $standardScript = ('{ 
            "type": "add-diagnostic", 
            "parameters": {
                "message": "custom error message"
            }
        }' | ConvertFrom-Json)
        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -Be @('ERR:  custom error message')
    }

    It 'allows errors explicitly' {
        $standardScript = ('{ 
            "type": "add-diagnostic", 
            "parameters": {
                "isWarning": false,
                "message": "custom error message"
            }
        }' | ConvertFrom-Json)
        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -Be @('ERR:  custom error message')
    }

    It 'sends custom warning messages' {
        $standardScript = ('{ 
            "type": "add-diagnostic", 
            "parameters": {
                "isWarning": true,
                "message": "custom warning message"
            }
        }' | ConvertFrom-Json)
        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -Be @('WARN: custom warning message')
    }
}
