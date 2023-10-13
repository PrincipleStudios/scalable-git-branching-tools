using module "./Get-MergeTree.psm1"

Describe 'Get-MergeTree' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Get-MergeTree.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Get-MergeTree.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    It 'merges successfully' {
        $mocks = Initialize-MergeTree 'feature/FOO-1' 'feature/FOO-2' 'result-treeish'

        $result = Get-MergeTree 'feature/FOO-1' 'feature/FOO-2'
        $result.isSuccess | Should -Be $true
        $result.treeish | Should -Be 'result-treeish'
        Invoke-VerifyMock $mocks -Times 1
    }
    
    It 'fails without conflicts' {
        $mocks = Initialize-MergeTree 'feature/FOO-1' 'feature/FOO-2' 'result-treeish' -fail

        $result = Get-MergeTree 'feature/FOO-1' 'feature/FOO-2'
        $result.isSuccess | Should -Be $false
        $result.treeish | Should -Be 'result-treeish'
        Invoke-VerifyMock $mocks -Times 1
    }
    
    It 'fails with conflicts' {
        $mocks = Initialize-MergeTree 'feature/FOO-1' 'feature/FOO-2' 'result-treeish' @('file1.txt', 'readme.md') -fail

        $result = Get-MergeTree 'feature/FOO-1' 'feature/FOO-2'
        $result.isSuccess | Should -Be $false
        $result.treeish | Should -Be 'result-treeish'
        $result.conflicts | Should -Be @('file1.txt', 'readme.md')
        Invoke-VerifyMock $mocks -Times 1
    }
}
