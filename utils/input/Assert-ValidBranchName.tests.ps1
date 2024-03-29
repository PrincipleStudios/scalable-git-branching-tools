Describe 'Assert-ValidBranchName' {
    BeforeAll {
        . "$PSScriptRoot/../testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Assert-ValidBranchName.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Assert-ValidBranchName.psm1"
    }
    
    BeforeEach {
        $fw = Register-Framework
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
    }

    Context 'when diagnostics are passed' {
        It 'allows a valid branch' {
            Initialize-AssertValidBranchName 'good-branch'
            Assert-ValidBranchName -branchName 'good-branch' -diagnostics $diag
            Should -ActualValue $diag.Count -BeExactly 0
        }
        It 'disallows an invalid branch name' {
            Initialize-AssertInvalidBranchName 'bad-branch'
            Assert-ValidBranchName -branchName 'bad-branch' -diagnostics $diag
            Should -ActualValue $diag.Count -BeExactly 1
            $diag[0].message | Should -Be "Invalid branch name specified: 'bad-branch'"
            $diag[0].level | Should -Be 'error'
        }
        It 'disallows a blank branch name' {
            Assert-ValidBranchName -branchName '' -diagnostics $diag
            Should -ActualValue $diag.Count -BeExactly 1
            $diag[0].message | Should -Be "No branch name was provided"
            $diag[0].level | Should -Be 'error'
        }
        It 'can accept multiple via a pipeline' {
            Initialize-AssertValidBranchName 'branch-a'
            Initialize-AssertValidBranchName 'branch-b'
            Initialize-AssertInvalidBranchName 'bad-branch-1'
            Initialize-AssertInvalidBranchName 'bad-branch-2'
            @('branch-a', 'branch-b', 'bad-branch-1', 'bad-branch-2') | Assert-ValidBranchName -diagnostics $diag
            Should -ActualValue $diag.Count -BeExactly 2
            $diag[0].message | Should -Be "Invalid branch name specified: 'bad-branch-1'"
            $diag[1].message | Should -Be "Invalid branch name specified: 'bad-branch-2'"
        }
    }

    Context 'when diagnostics are not passed passed' {
        It 'allows a valid branch' {
            Initialize-AssertValidBranchName 'good-branch'
            Assert-ValidBranchName -diagnostics $nil -branchName 'good-branch'
            Should -ActualValue $diag.Count -BeExactly 0
        }
        It 'disallows an invalid branch name' {
            Initialize-AssertInvalidBranchName 'bad-branch'
            { Assert-ValidBranchName -diagnostics $nil -branchName 'bad-branch' } | Should -Throw "Invalid branch name specified: 'bad-branch'"
        }
    }


}