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

            Initialize-NoCurrentBranch
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar') -untracked @('foo', 'bar')

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

        }
        
        It 'ensures local branches are updated' {
            Initialize-NoCurrentBranch
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar')

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'can execute a dry run' {
            Initialize-NoCurrentBranch
            $mocks = Initialize-FinalizeActionTrackDryRun @('foo', 'bar')

            $dryRunCommands = Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics -dryRun

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
            
            $dryRunCommands | Should -Be @(
                'git branch foo "refs/remotes/origin/foo" -f'
                'git branch bar "refs/remotes/origin/bar" -f'
            )
        }
        
        It 'updates the current branch' {
            Initialize-CurrentBranch 'foo'
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar')

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1

        }
        
        It 'updates no branches if they are untracked' {
            Initialize-CurrentBranch 'foo'
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar')

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
        
        It 'updates the current branch even if it is untracked' {
            Initialize-CurrentBranch 'foo'
            $mocks = Initialize-FinalizeActionTrackSuccess @('foo', 'bar') -untracked @('foo')

            Invoke-FinalizeAction $standardScript -diagnostics $fw.diagnostics

            Invoke-FlushAssertDiagnostic $fw.diagnostics
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
