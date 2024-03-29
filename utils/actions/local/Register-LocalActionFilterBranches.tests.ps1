Describe 'local action "filter-branches"' {
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

    It 'can filter branches' {
        $standardScript = ('{ 
            "type": "filter-branches", 
            "parameters": {
                "include": ["foo","bar","baz"],
                "exclude": ["baz"]
            }
        }' | ConvertFrom-Json)

        $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $outputs | Should -Be @('foo', 'bar')
    }

    It 'can filter to a single branch and return an array' {
        $standardScript = ('{ 
            "type": "filter-branches", 
            "parameters": {
                "include": ["foo","bar","baz"],
                "exclude": ["bar", "baz"]
            }
        }' | ConvertFrom-Json)

        $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        Should -ActualValue $outputs -Be @('foo')
    }

    It 'allows for no branches to remove' {
        $standardScript = ('{ 
            "type": "filter-branches", 
            "parameters": {
                "include": ["foo","bar"],
                "exclude": []
            }
        }' | ConvertFrom-Json)

        $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $outputs | Should -Be @('foo', 'bar')
    }

    It 'allows exclusions not from the include list' {
        $standardScript = ('{ 
            "type": "filter-branches", 
            "parameters": {
                "include": ["foo","bar"],
                "exclude": ["baz"]
            }
        }' | ConvertFrom-Json)

        $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $outputs | Should -Be @('foo', 'bar')
    }

    It 'can remove all branches' {
        $standardScript = ('{ 
            "type": "filter-branches", 
            "parameters": {
                "include": ["foo","bar"],
                "exclude": ["foo","bar"]
            }
        }' | ConvertFrom-Json)

        $outputs = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        # Powershell really doesn't like empty arrays, tends to convert them to $null
        Should -ActualValue $outputs -Be $null
    }
}
