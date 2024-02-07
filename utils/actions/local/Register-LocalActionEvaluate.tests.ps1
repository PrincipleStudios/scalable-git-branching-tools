Describe 'local action "evaluate"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../actions.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    It 'can evaluate standard strings' {
        $result = Invoke-LocalAction ('{ 
            "type": "evaluate", 
            "parameters": {
                "result": "Standard string"
            }
        }' | ConvertFrom-Json) -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $result | Should -Be "Standard string"
    }

    It 'can evaluate complex objects' {
        $result = Invoke-LocalAction ('{ 
            "type": "evaluate", 
            "parameters": {
                "result": {
                    "one": 1,
                    "two": 2,
                }
            }
        }' | ConvertFrom-Json) -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $result.one | Should -Be 1
        $result.two | Should -Be 2
    }

    It 'can return arrays' {
        $result = Invoke-LocalAction ('{ 
            "type": "evaluate", 
            "parameters": {
                "result": [1,2,3]
            }
        }' | ConvertFrom-Json) -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $result | Should -Be @(1, 2, 3)
    }
}
