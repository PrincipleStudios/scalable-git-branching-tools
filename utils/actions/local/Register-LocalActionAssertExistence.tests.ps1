Describe 'local action "assert-existence"' {
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

    function AddStandardTests() {
        Context 'with should exist' {
            BeforeEach {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
                $standardScript = ('{ 
                    "type": "assert-existence", 
                    "parameters": {
                        "branches": ["foo", "feature/bar"],
                        "shouldExist": true
                    }
                }' | ConvertFrom-Json)
            }

            It 'does nothing when everything exists' {
                Initialize-LocalActionAssertExistence -branches @('foo', 'feature/bar') -shouldExist $true

                Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            }

            It 'gives one error if one fails' {
                Initialize-LocalActionAssertExistence -branches @('foo') -shouldExist $true
                Initialize-LocalActionAssertExistence -branches @('feature/bar') -shouldExist $false

                Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                Invoke-FlushAssertDiagnostic $fw.diagnostics

                $remote = $(Get-Configuration).remote
                $fw.assertDiagnosticOutput | Should -Be @("ERR:  Branch feature/bar did not exist$($remote ? " on remote $remote" : '').")
            }

            It 'gives more errors if multiple fail' {
                Initialize-LocalActionAssertExistence -branches @('foo', 'feature/bar') -shouldExist $false

                Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                Invoke-FlushAssertDiagnostic $fw.diagnostics

                $remote = $(Get-Configuration).remote
                $fw.assertDiagnosticOutput | Should -Be @(
                    "ERR:  Branch foo did not exist$($remote ? " on remote $remote" : '')."
                    "ERR:  Branch feature/bar did not exist$($remote ? " on remote $remote" : '')."
                )
            }
        }
        
        Context 'with should not exist' {
            BeforeEach {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
                $standardScript = ('{ 
                    "type": "assert-existence", 
                    "parameters": {
                        "branches": ["foo", "feature/bar"],
                        "shouldExist": false
                    }
                }' | ConvertFrom-Json)
            }

            It 'does nothing when everything is missing' {
                Initialize-LocalActionAssertExistence -branches @('foo', 'feature/bar') -shouldExist $false

                Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                Invoke-FlushAssertDiagnostic $fw.diagnostics
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            }

            It 'gives one error if one fails' {
                Initialize-LocalActionAssertExistence -branches @('foo') -shouldExist $true
                Initialize-LocalActionAssertExistence -branches @('feature/bar') -shouldExist $false

                Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                Invoke-FlushAssertDiagnostic $fw.diagnostics

                $remote = $(Get-Configuration).remote
                $fw.assertDiagnosticOutput | Should -Be @("ERR:  Branch foo already exists$($remote ? " on remote $remote" : '').")
            }

            It 'gives more errors if multiple fail' {
                Initialize-LocalActionAssertExistence -branches @('foo', 'feature/bar') -shouldExist $true

                Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

                Invoke-FlushAssertDiagnostic $fw.diagnostics

                $remote = $(Get-Configuration).remote
                $fw.assertDiagnosticOutput | Should -Be @(
                    "ERR:  Branch foo already exists$($remote ? " on remote $remote" : '')."
                    "ERR:  Branch feature/bar already exists$($remote ? " on remote $remote" : '')."
                )
            }
        }
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
        }
        AddStandardTests
    }

    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
        }
        AddStandardTests
    }
}
