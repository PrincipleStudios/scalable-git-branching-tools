Describe 'finalize action "checkout"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-FinalizeAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionCheckout.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        $fw = Register-Framework

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $standardScript = ('{ 
            "type": "checkout", 
            "parameters": {
                "HEAD": "new-branch"
            }
        }' | ConvertFrom-Json)
        Initialize-ToolConfiguration -noRemote
    }

    It 'handles standard functionality' {
        $mocks = @(
            Initialize-CleanWorkingDirectory
            Invoke-MockGitModule -ModuleName 'Invoke-CheckoutBranch' `
                -gitCli "checkout new-branch"
        )
        
        Invoke-FinalizeAction $standardScript -diagnostics $diag
        $diag | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'handles dry-run functionality' {
        $dryRunCommands = Invoke-FinalizeAction $standardScript -diagnostics $diag -dryRun
        $diag | Should -BeNullOrEmpty
        
        $dryRunCommands | Should -Contain 'git checkout new-branch'
    }

    It 'fails if the working directory is not clean' {
        $mocks = @(
            Initialize-DirtyWorkingDirectory
        )
        
        Invoke-FinalizeAction $standardScript -diagnostics $diag
        { Assert-Diagnostics $diag } | Should -Throw
        Get-HasErrorDiagnostic $diag | Should -BeTrue
        $fw.assertDiagnosticOutput | Should -Contain 'ERR:  Git working directory is not clean.'
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'handles standard functionality using mocks' {
        $mocks = Initialize-FinalizeActionCheckout 'new-branch'
        Invoke-FinalizeAction $standardScript -diagnostics $diag
        $diag | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'reports failures' {
        Initialize-FinalizeActionCheckout 'new-branch' -fail
        Invoke-FinalizeAction $standardScript -diagnostics $diag
        Get-HasErrorDiagnostic $diag | Should -Be $true
    }
}
