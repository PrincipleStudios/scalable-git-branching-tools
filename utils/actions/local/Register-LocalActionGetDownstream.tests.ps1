Describe 'local action "get-downstream"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../actions.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        Initialize-ToolConfiguration

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        Initialize-AllUpstreamBranches @{
            'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-124' = @("feature/FOO-123")
            'feature/FOO-123' = @("main")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")

            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }
    }

    It 'gets downstream branches' {
        $result = Invoke-LocalAction ('{
            "type": "get-downstream", 
            "parameters": {
                "target": "feature/FOO-123",
                "recurse": false
            }
        }' | ConvertFrom-Json) -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $result.Length | Should -Be 2
        $result | Should -Contain 'integrate/FOO-123_XYZ-1'
        $result | Should -Contain 'feature/FOO-124'
    }

    It 'gets downstream branches recursively' {
        $result = Invoke-LocalAction ('{
            "type": "get-downstream", 
            "parameters": {
                "target": "feature/FOO-123",
                "recurse": true
            }
        }' | ConvertFrom-Json) -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $result.Length | Should -Be 3
        $result | Should -Contain 'integrate/FOO-123_XYZ-1'
        $result | Should -Contain 'feature/FOO-124'
        $result | Should -Contain 'rc/1.1.0'
    }

    It 'gets downstream branches with overrides' {
        [string[]]$result = Invoke-LocalAction ('{
            "type": "get-downstream", 
            "parameters": {
                "target": "infra/new",
                "overrideUpstreams": {
                    "feature/FOO-123": "infra/new",
                    "infra/new": "main"
                }
            }
        }' | ConvertFrom-Json) -diagnostics $fw.diagnostics

        Invoke-FlushAssertDiagnostic $fw.diagnostics
        $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        $result.Length | Should -Be 1
        $result | Should -Contain 'feature/FOO-123'
    }
}
