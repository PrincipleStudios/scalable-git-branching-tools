Describe 'local action "validate-branch-names"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionValidateBranchNames.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "validate-branch-names", 
            "parameters": {
                "branches": ["foo", "bar", "baz"]
            }
        }' | ConvertFrom-Json)
    }

    It 'handles standard functionality' {
        Initialize-LocalActionValidateBranchNamesSuccess @('foo', 'bar', 'baz')

        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
    }

    It 'throws errors for invalid branch names' {
        Initialize-AssertValidBranchName 'foo'
        Initialize-AssertValidBranchName 'bar'
        Initialize-AssertInvalidBranchName 'baz'

        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $true
        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -contain "ERR:  Invalid branch name specified: 'baz'"
    }

    It 'prevents blank branch names' {
        $standardScript = ('{ 
            "type": "validate-branch-names", 
            "parameters": {
                "branches": [""]
            }
        }' | ConvertFrom-Json)

        Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $true
        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -contain "ERR:  No branch name was provided"
    }
}
