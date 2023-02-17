
Describe 'Invoke-MergeBranches' {
    BeforeEach {
        . $PSScriptRoot/Invoke-MergeBranches.ps1

        $foo1Filter = { ($args -join ' ') -eq 'merge feature/FOO-1 --quiet --commit --no-edit --no-squash' }
        $foo2Filter = { ($args -join ' ') -eq 'merge feature/FOO-2 --quiet --commit --no-edit --no-squash' }
        $foo3Filter = { ($args -join ' ') -eq 'merge feature/FOO-3 --quiet --commit --no-edit --no-squash' }
        $abortFilter = { ($args -join ' ') -eq 'merge --abort' }
    }

    It 'throws and aborts midway if exit code is non-zero' {
        Mock git -ParameterFilter $foo1Filter { $Global:LASTEXITCODE = 0 } -Verifiable
        Mock git -ParameterFilter $foo2Filter { $Global:LASTEXITCODE = 1 } -Verifiable
        Mock git -ParameterFilter $foo3Filter { $Global:LASTEXITCODE = 0 } -Verifiable
        Mock git -ParameterFilter $abortFilter { $Global:LASTEXITCODE = 0 } -Verifiable

        $result = Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3')  -quiet
        $result -is [InvalidMergeResult] | Should -Be $true
        $result.branch | Should -Be 'feature/FOO-2'
        { $result.ThrowIfInvalid() } | Should -Throw
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo1Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo2Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $foo3Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $abortFilter
    }
    It 'throws midway if exit code is non-zero but leaves the merge half-completed when -noAbort is passed' {
        Mock git -ParameterFilter $foo1Filter { $Global:LASTEXITCODE = 0 } -Verifiable
        Mock git -ParameterFilter $foo2Filter { $Global:LASTEXITCODE = 1 } -Verifiable
        Mock git -ParameterFilter $foo3Filter { $Global:LASTEXITCODE = 0 } -Verifiable
        Mock git -ParameterFilter $abortFilter { $Global:LASTEXITCODE = 0 } -Verifiable

        $result = Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -noAbort  -quiet
        $result -is [InvalidMergeResult] | Should -Be $true
        $result.branch | Should -Be 'feature/FOO-2'
        { $result.ThrowIfInvalid() } | Should -Throw
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo1Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo2Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $foo3Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $abortFilter
    }
    It 'does not throw or abort if exit code is zero' {
        Mock git -ParameterFilter $foo1Filter { $Global:LASTEXITCODE = 0 } -Verifiable
        Mock git -ParameterFilter $foo2Filter { $Global:LASTEXITCODE = 0 } -Verifiable
        Mock git -ParameterFilter $foo3Filter { $Global:LASTEXITCODE = 0 } -Verifiable
        Mock git -ParameterFilter $abortFilter { $Global:LASTEXITCODE = 0 } -Verifiable

        $result = Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -quiet
        $result -is [SuccessfulMergeResult] | Should -Be $true
        { $result.ThrowIfInvalid() } | Should -Not -Throw
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo1Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo2Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo3Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $abortFilter
    }
}
