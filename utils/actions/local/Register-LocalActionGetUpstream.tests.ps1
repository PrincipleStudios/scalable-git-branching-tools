Describe 'local action "get-upstream"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionGetUpstream.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "get-upstream", 
            "parameters": {
                "target": "my-branch"
            }
        }' | ConvertFrom-Json)
    }

    function Initialize-StandardTests {
        It 'gets the configured upstream branches' {
            Initialize-UpstreamBranches @{
                'my-branch' = @('main')
            }
    
            $results = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics
    
            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            $results | Should -Be @('main')
        }

        It 'gets all configured upstream branches' {
            Initialize-UpstreamBranches @{
                'my-branch' = @('feature-base', 'infra/refactor')
            }
    
            $results = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics
    
            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            $results | Should -Be @('feature-base', 'infra/refactor')
        }

        It 'gets an empty array if no configuration exists' {
            Initialize-UpstreamBranches @{
                'my-other-branch' = @('feature-base', 'infra/refactor')
            }
    
            $results = Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics
    
            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            $results | Should -Be @()
        }
    }

    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-AnyUpstreamBranches
        }

        Initialize-StandardTests
    }

    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-AnyUpstreamBranches
        }

        Initialize-StandardTests
    }
}
