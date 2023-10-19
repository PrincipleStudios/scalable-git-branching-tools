Describe 'local action scripting' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-LocalAction.psm1"
        . "$PSScriptRoot/../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    It 'invokes scripts by default' {
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

    It 'will run the script if a condition is specified that evaluates to true' {
        $standardScript = ('{ 
            "type": "add-diagnostic",
            "condition": true,
            "parameters": {
                "message": "custom error message"
            }
        }' | ConvertFrom-Json)
        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -Be @('ERR:  custom error message')
    }

    It 'will skip the script if a condition is specified that evaluates to false' {
        $standardScript = ('{ 
            "type": "add-diagnostic",
            "condition": false,
            "parameters": {
                "message": "custom error message"
            }
        }' | ConvertFrom-Json)
        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
    }

    It 'will run the script if a condition is specified that evaluates to a truthy value' {
        $standardScript = ('{ 
            "type": "add-diagnostic",
            "condition": "this is truthy",
            "parameters": {
                "message": "custom error message"
            }
        }' | ConvertFrom-Json)
        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -Be @('ERR:  custom error message')
    }

    It 'will skip the script if a condition is specified that evaluates to a falsy value' {
        $standardScript = ('{ 
            "type": "add-diagnostic",
            "condition": "",
            "parameters": {
                "message": "custom error message"
            }
        }' | ConvertFrom-Json)
        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
    }
}
