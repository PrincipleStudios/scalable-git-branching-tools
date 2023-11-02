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
        $result.hasChanges | Should -Be $false
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
        $result.hasChanges | Should -Be $true
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
        $result.hasChanges | Should -Be $true
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $false
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can handle the last branch failing' {
        $mocks = Initialize-MergeTogether `
            -allBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') `
            -successfulBranches @('feature/FOO-1', 'feature/FOO-2') `
            -resultCommitish 'result-commitish' `
            -messageTemplate 'Merge {}'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -diagnostics $fw.diagnostics -asWarnings
        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @('feature/FOO-3')
        $result.successful | Should -Be @('feature/FOO-1', 'feature/FOO-2')
        $result.hasChanges | Should -Be $true
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $false
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'can handle the second branch failing with a source' {
        $mocks = Initialize-MergeTogether `
            -allBranches @('feature/FOO-2', 'feature/FOO-3') `
            -successfulBranches @('feature/FOO-2') `
            -source 'feature/FOO-1' `
            -resultCommitish 'result-commitish' `
            -messageTemplate 'Merge {}'

        $result = Invoke-MergeTogether @('feature/FOO-2', 'feature/FOO-3') -source 'feature/FOO-1' -diagnostics $fw.diagnostics -asWarnings
        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @('feature/FOO-3')
        $result.successful | Should -Be @('feature/FOO-2')
        $result.hasChanges | Should -Be $true
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $false
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'starts with the source' {
        $mocks = Initialize-MergeTogether `
            -allBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') `
            -successfulBranches @('feature/FOO-1', 'feature/FOO-3') `
            -source 'main' `
            -resultCommitish 'result-commitish' `
            -messageTemplate 'Merge {}'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -source 'main' -diagnostics $fw.diagnostics
        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @('feature/FOO-2')
        $result.successful | Should -Be @('feature/FOO-1', 'feature/FOO-3')
        $result.hasChanges | Should -Be $true
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $true
        Invoke-VerifyMock $mocks -Times 1
    }
    
    It "fails if the source can't resolve" {
        $mocks = Initialize-MergeTogetherAllFailed 'main'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -source 'main' -diagnostics $fw.diagnostics
        $result.result | Should -Be $null
        # ONly checked the source, so that's all that will be relayed in the failure
        $result.failed | Should -Be @('main')
        $result.successful | Should -BeNullOrEmpty
        $fw.diagnostics | Should -Not -BeNullOrEmpty
        $result.hasChanges | Should -Be $false
        Get-HasErrorDiagnostic $fw.diagnostics | Should -Be $true
        Invoke-VerifyMock $mocks -Times 1
    }
    
    It 'does not throw or abort if exit code is zero' {
        $mocks = Initialize-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -successfulBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -resultCommitish 'result-commitish'

        $result = Invoke-MergeTogether @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -diagnostics $fw.diagnostics

        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @()
        $result.successful | Should -Be @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3')
        $result.hasChanges | Should -Be $true
        $fw.diagnostics | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }
    
    It 'succeeds with no changes if only one branch is provided' {
        $mocks = Initialize-MergeTogether @('feature/FOO-1') -successfulBranches @('feature/FOO-1') -resultCommitish 'result-commitish'

        $result = Invoke-MergeTogether @('feature/FOO-1') -diagnostics $fw.diagnostics

        $result.result | Should -Be 'result-commitish'
        $result.failed | Should -Be @()
        $result.successful | Should -Be @('feature/FOO-1')
        $result.hasChanges | Should -Be $false
        $fw.diagnostics | Should -BeNullOrEmpty
        Invoke-VerifyMock $mocks -Times 1
    }
}
