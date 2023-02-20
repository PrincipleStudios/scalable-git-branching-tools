BeforeAll {
    . $PSScriptRoot/Invoke-PreserveBranch.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Invoke-PreserveBranch' {
    BeforeAll {
        Mock git {
            throw "Unmocked git command: $args"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch --show-current' } { 'my-custom-branch' }

        . $PSScriptRoot/Assert-CleanWorkingDirectory.ps1
        Mock -CommandName Assert-CleanWorkingDirectory { }

    }

    It 'by default checks out the previous branch' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Verifiable { $Global:LASTEXITCODE = 0 }

        Invoke-PreserveBranch { My-Func }

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Times 1
    }
    It 'runs custom cleanup' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        function My-Func2() { }
        Mock -CommandName My-Func2 -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Verifiable { $Global:LASTEXITCODE = 0 }

        Invoke-PreserveBranch { My-Func } -cleanup { My-Func2 }

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke -CommandName My-Func2 -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Times 1
    }
    It 'passes the original ref name to the custom cleanup' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        function My-Func2() { }
        Mock -CommandName My-Func2 -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Verifiable { $Global:LASTEXITCODE = 0 }

        Invoke-PreserveBranch { My-Func } -cleanup {
            $args[0] | Should -Be 'my-custom-branch'
            My-Func2
        }

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke -CommandName My-Func2 -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Times 1
    }
    It 'does nothing on success with the onlyIfError flag' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }

        Invoke-PreserveBranch { My-Func } -onlyIfError

        Should -Invoke -CommandName My-Func -Times 1
    }
    It 'checks out the original on a failure' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { throw 'error' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Verifiable { $Global:LASTEXITCODE = 0 }

        { Invoke-PreserveBranch { My-Func } -onlyIfError } | Should -Throw

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Times 1
    }


    It 'checks out the original commitish on a failure' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { throw 'error' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch --show-current' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse HEAD' } { 'baadf00d' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout baadf00d' } -Verifiable { $Global:LASTEXITCODE = 0 }

        { Invoke-PreserveBranch { My-Func } -onlyIfError } | Should -Throw

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout baadf00d' } -Times 1
    }

    It 'skips the original cleanup but still runs the passed cleanup if the corresponding flag is passed' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        function My-Func2() { }
        Mock -CommandName My-Func2 -Verifiable { }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch --show-current' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse HEAD' } { 'baadf00d' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout baadf00d' } -Verifiable { $Global:LASTEXITCODE = 0 }

        Invoke-PreserveBranch { My-Func } -cleanup { My-Func2 } -noDefaultCleanup

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke -CommandName My-Func2 -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 0
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout baadf00d' } -Times 0
    }

    It 'by default returns the original value' {
        $expectedResult = 15
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { return $expectedResult }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Verifiable { $Global:LASTEXITCODE = 0 }

        $result = Invoke-PreserveBranch { return My-Func }

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout my-custom-branch' } -Times 1
        $result | Should -Be $expectedResult
    }

    It 'checks out the original commitish when given a ResultWithCleanup result' {
        $expectedResult = 42
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { return New-Object ResultWithCleanup $expectedResult }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch --show-current' } { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse HEAD' } { 'baadf00d' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Verifiable { }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout baadf00d' } -Verifiable { $Global:LASTEXITCODE = 0 }

        $result = Invoke-PreserveBranch { return My-Func }

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'reset --hard' } -Times 1
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'checkout baadf00d' } -Times 1
        $result | Should -Be $expectedResult
    }

}