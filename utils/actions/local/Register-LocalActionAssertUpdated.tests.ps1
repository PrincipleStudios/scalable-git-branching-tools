Describe 'local action "assert-updated"' {
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

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "assert-updated", 
            "parameters": {
                "downstream": "rc/next",
                "upstream": "main",
            }
        }' | ConvertFrom-Json)

        Initialize-ToolConfiguration
    }

    It 'handles successful cases' {
        Initialize-LocalActionAssertUpdatedSuccess -downstream 'rc/next' -upstream 'main'

        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
    }

    It 'reports an error for conflicts' {
        Initialize-LocalActionAssertUpdatedFailure -downstream 'rc/next' -upstream 'main' -withConflict

        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -Contain 'ERR:  The branch origin/main conflicts with origin/rc/next'
    }

    It 'reports an error if there are changes' {
        Initialize-LocalActionAssertUpdatedFailure -downstream 'rc/next' -upstream 'main'

        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -Contain 'ERR:  The branch origin/main has changes that are not in origin/rc/next'
    }
}
