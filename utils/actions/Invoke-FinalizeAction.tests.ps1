Describe 'finalize action scripting' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../actions.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-FinalizeAction.psm1"
        . "$PSScriptRoot/../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
        
        Initialize-ToolConfiguration
        Initialize-NoCurrentBranch
    }

    It 'ensures local branches are updated' {
        $standardScript = ('{ 
            "type": "track", 
            "parameters": {
                "branches": ["foo"]
            }
        }' | ConvertFrom-Json)
        $mocks = Initialize-FinalizeActionTrackSuccess @('foo')

        Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1

    }
    
    It 'will run the script if a condition is specified that evaluates to true' {
        $standardScript = ('{ 
            "type": "track",
            "condition": true,
            "parameters": {
                "branches": ["foo"]
            }
        }' | ConvertFrom-Json)
        $mocks = Initialize-FinalizeActionTrackSuccess @('foo')

        Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'will skip the script if a condition is specified that evaluates to false' {
        $standardScript = ('{ 
            "type": "track",
            "condition": false,
            "parameters": {
                "branches": ["foo"]
            }
        }' | ConvertFrom-Json)

        Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
    }

    It 'will run the script if a condition is specified that evaluates to a truthy value' {
        $standardScript = ('{ 
            "type": "track",
            "condition": "this is truthy",
            "parameters": {
                "branches": ["foo"]
            }
        }' | ConvertFrom-Json)
        $mocks = Initialize-FinalizeActionTrackSuccess @('foo')

        Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

        Invoke-VerifyMock $mocks -Times 1
    }

    It 'will skip the script if a condition is specified that evaluates to a falsy value' {
        $standardScript = ('{ 
            "type": "track",
            "condition": "",
            "parameters": {
                "branches": ["foo"]
            }
        }' | ConvertFrom-Json)

        Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
    }
}
