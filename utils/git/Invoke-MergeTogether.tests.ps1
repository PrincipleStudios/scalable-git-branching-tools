using module "./Invoke-MergeTogether.psm1"

Describe 'Invoke-MergeTogether' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-MergeTogether.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-MergeTogether.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    It 'reports a major failure if no branches are successful' {
        $mocks = Initialize-MergeTogether `
            -allBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') `
            -messageTemplate 'Merge {}'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -diagnostics $fw.diagnostics
        $result.result | Should -Be $null
        $result.failed | Should -Be @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3')
        $result.successful | Should -BeNullOrEmpty
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $true
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'merges the branches that it can' {
        $mocks = Initialize-MergeTogether `
            -allBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') `
            -successfulBranches @('feature/FOO-1', 'feature/FOO-3') `
            -resultCommitish 'result-commitish' `
            -messageTemplate 'Merge {}'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -diagnostics $fw.diagnostics
        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @('feature/FOO-2')
        $result.successful | Should -Be @('feature/FOO-1', 'feature/FOO-3')
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $true
        Invoke-VerifyMock $mocks -Times 1
    }
    
    It 'can flag failed merges only as warnings' {
        $mocks = Initialize-MergeTogether `
            -allBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') `
            -successfulBranches @('feature/FOO-1', 'feature/FOO-3') `
            -resultCommitish 'result-commitish' `
            -messageTemplate 'Merge {}'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -diagnostics $fw.diagnostics -asWarnings
        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @('feature/FOO-2')
        $result.successful | Should -Be @('feature/FOO-1', 'feature/FOO-3')
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $false
        Invoke-VerifyMock $mocks -Times 1
    }
    
    It 'does not throw or abort if exit code is zero' {
        $mocks = Initialize-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -successfulBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -resultCommitish 'result-commitish'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -diagnostics $fw.diagnostics

        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @()
        $result.successful | Should -Be @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3')
        $fw.diagnostics | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }
}
