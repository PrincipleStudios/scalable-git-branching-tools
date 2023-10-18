Describe 'finalize action "track"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../actions.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-FinalizeAction.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "track", 
            "parameters": {
                "branches": ["foo","bar"]
            }
        }' | ConvertFrom-Json)
    }

    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }
        
        It 'does nothing' {
            $result = Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            $result | Should -BeNullOrEmpty
            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty

        }
    }

    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'forces creation of local branches' {
            $standardScript = ('{ 
                "type": "track", 
                "parameters": {
                    "createIfNotTracked": true,
                    "branches": ["foo","bar"]
                }
            }' | ConvertFrom-Json)

            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar') -untracked @('foo', 'bar')

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

        }
        
        It 'ensures local branches are updated' {
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar')

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

        }
        
        It 'updates the current branch' {
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar') -currentBranch 'foo'

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

        }
        
        It 'updates no branches if they are untracked' {
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar') -currentBranch 'foo'

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

        }
        
        It 'updates the current branch even if it is untracked' {
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar') -untracked @('foo') -currentBranch 'foo'

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

        }
    }
}
