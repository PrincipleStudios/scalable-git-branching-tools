Describe 'finalize action "set-branches"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-FinalizeAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionSetBranches.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = New-Diagnostics
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $output = Register-Diagnostics -throwInsteadOfExit
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "set-branches", 
            "parameters": {
                "branches": {
                    "_upstream": "new-upstream-commitish",
                    "other": "other-commitish",
                    "another": "another-commitish",
                }
            }
        }' | ConvertFrom-Json)
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        [hashtable]$standardBranches = @{
            _upstream = "new-upstream-commitish";
            other ="other-commitish";
            another ="another-commitish";
        }
    }

    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }

        It 'handles standard functionality' {
            $mocks = @(
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "branch _upstream new-upstream-commitish -f"
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "branch other other-commitish -f"
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "branch another another-commitish -f"
            )
            
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'handles standard functionality using mocks' {
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'reports failures' {
            Initialize-FinalizeActionSetBranches $standardBranches -fail
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            Get-HasErrorDiagnostic $diag | Should -Be $true
        }
    }

    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'handles standard functionality' {
            $mocks = @(
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "push origin --atomic new-upstream-commitish:refs/heads/_upstream other-commitish:refs/heads/other another-commitish:refs/heads/another"
            )
            
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'handles standard functionality using mocks' {
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'reports failures' {
            Initialize-FinalizeActionSetBranches $standardBranches -fail
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            Get-HasErrorDiagnostic $diag | Should -Be $true
        }
    }
    Context 'with remote where atomic is disabled' {
        BeforeEach {
            Initialize-ToolConfiguration -noAtomicPush
        }

        It 'handles standard functionality' {
            $mocks = @(
                Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                    -gitCli "push origin new-upstream-commitish:refs/heads/_upstream other-commitish:refs/heads/other another-commitish:refs/heads/another"
            )
            
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'handles standard functionality using mocks' {
            $mocks = Initialize-FinalizeActionSetBranches $standardBranches
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            $diag | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'reports failures' {
            Initialize-FinalizeActionSetBranches $standardBranches -fail
            Invoke-FinalizeAction $standardScript -diagnostics $diag
            Get-HasErrorDiagnostic $diag | Should -Be $true
        }
    }
}
