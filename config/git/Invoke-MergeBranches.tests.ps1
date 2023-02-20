using module "./Invoke-MergeBranches.psm1"

Describe 'Invoke-MergeBranches' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/Invoke-MergeBranches.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-MergeBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-VerifyMock.psm1"
        Initialize-QuietMergeBranches
    }

    It 'throws and aborts midway if exit code is non-zero' {
        $foo1 = Initialize-InvokeMergeSuccess 'feature/FOO-1'
        $foo2 = Initialize-InvokeMergeFailure 'feature/FOO-2'
        $foo3 = Initialize-InvokeMergeSuccess 'feature/FOO-3'

        $result = Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3')  -quiet
        $result.isValid | Should -Be $false
        $result.branch | Should -Be 'feature/FOO-2'
        { $result.ThrowIfInvalid() } | Should -Throw "Could not complete the merge."
        Invoke-VerifyMock $foo1 -Times 1
        Invoke-VerifyMock $foo2 -Times 1
        Invoke-VerifyMock $foo3 -Times 0
        Invoke-VerifyMock $(Get-MergeAbortFilter) -Times 1
    }
    It 'throws midway if exit code is non-zero but leaves the merge half-completed when -noAbort is passed' {
        $foo1 = Initialize-InvokeMergeSuccess 'feature/FOO-1'
        $foo2 = Initialize-InvokeMergeFailure 'feature/FOO-2'
        $foo3 = Initialize-InvokeMergeSuccess 'feature/FOO-3' -noAbort

        $result = Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -noAbort  -quiet
        $result.isValid | Should -Be $false
        $result.branch | Should -Be 'feature/FOO-2'
        { $result.ThrowIfInvalid() } | Should -Throw "Could not complete the merge."
        Invoke-VerifyMock $foo1 -Times 1
        Invoke-VerifyMock $foo2 -Times 1
        Invoke-VerifyMock $foo3 -Times 0
        Invoke-VerifyMock $(Get-MergeAbortFilter) -Times 0
    }
    It 'does not throw or abort if exit code is zero' {
        $foo1 = Initialize-InvokeMergeSuccess 'feature/FOO-1'
        $foo2 = Initialize-InvokeMergeSuccess 'feature/FOO-2'
        $foo3 = Initialize-InvokeMergeSuccess 'feature/FOO-3'

        $result = Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -quiet
        $result.isValid | Should -Be $true
        { $result.ThrowIfInvalid() } | Should -Not -Throw
        Invoke-VerifyMock $foo1 -Times 1
        Invoke-VerifyMock $foo2 -Times 1
        Invoke-VerifyMock $foo3 -Times 1
        Invoke-VerifyMock $(Get-MergeAbortFilter) -Times 0
    }
}
