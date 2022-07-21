BeforeAll {
    . $PSScriptRoot/Invoke-MergeBranches.ps1
}

Describe 'Invoke-MergeBranches' {
    BeforeEach {
        $foo1Filter = { ($args -join ' ') -eq 'merge feature/FOO-1 --quiet --commit --no-edit --no-squash' }
        $foo2Filter = { ($args -join ' ') -eq 'merge feature/FOO-2 --quiet --commit --no-edit --no-squash' }
        $foo3Filter = { ($args -join ' ') -eq 'merge feature/FOO-3 --quiet --commit --no-edit --no-squash' }
        $abortFilter = { ($args -join ' ') -eq 'merge --abort' }
    }

    It 'throws and aborts midway if exit code is non-zero' {
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $foo1Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 1
        } -ParameterFilter $foo2Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $foo3Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $abortFilter -Verifiable
            
        { Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') } | Should -Throw
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo1Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo2Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $foo3Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $abortFilter
    }
    It 'throws midway if exit code is non-zero but leaves the merge half-completed when -noAbort is passed' {
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $foo1Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 1
        } -ParameterFilter $foo2Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $foo3Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $abortFilter -Verifiable
            
        { Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -noAbort } | Should -Throw
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo1Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo2Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $foo3Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $abortFilter
    }
    It 'does not throw or abort if exit code is zero' {
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $foo1Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $foo2Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $foo3Filter -Verifiable
        Mock git {
            $Global:LASTEXITCODE = 0
        } -ParameterFilter $abortFilter -Verifiable
            
        Invoke-MergeBranches @('feature/FOO-1', 'feature/FOO-2', 'feature/FOO-3') -quiet
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo1Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo2Filter
        Should -Invoke -CommandName git -Times 1 -ParameterFilter $foo3Filter
        Should -Invoke -CommandName git -Times 0 -ParameterFilter $abortFilter
    }
}
