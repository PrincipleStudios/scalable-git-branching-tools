Describe 'local action "assert-pushed"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionAssertPushed.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "assert-pushed", 
            "parameters": {
                "target": "my-branch"
            }
        }' | ConvertFrom-Json)
    }

    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'passes if a branch is up-to-date' {
            Initialize-LocalActionAssertPushedSuccess 'my-branch'

            Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'passes if a branch has no local' {
            Initialize-RemoteBranchNotTracked 'my-branch'

            Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'fails if a branch has not pushed changes' {
            Initialize-LocalActionAssertPushedAhead 'my-branch'

            Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -Contain 'ERR:  The local branch for my-branch has changes that are not pushed to the remote'
        }
    }
    
    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }

        It 'always passes' {
            Invoke-LocalAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }
    }
}
