BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/Invoke-PreserveBranch.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-VerifyMock.psm1"
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Invoke-PreserveBranch' {
    BeforeAll {
        . "$PSScriptRoot/../core/Lock-Git.mocks.ps1"

        Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-PreserveBranch.mocks.psm1"

        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-custom-branch'
    }

    It 'by default checks out the previous branch' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        $mocks = Initialize-PreserveBranchCleanup

        Invoke-PreserveBranch { My-Func }

        Should -Invoke -CommandName My-Func -Times 1
        Invoke-VerifyMock $mocks -Times 1
    }
    It 'runs custom cleanup' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        function My-Func2() { }
        Mock -CommandName My-Func2 -Verifiable { }
        $mocks = Initialize-PreserveBranchCleanup

        Invoke-PreserveBranch { My-Func } -cleanup { My-Func2 }

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke -CommandName My-Func2 -Times 1
        Invoke-VerifyMock $mocks -Times 1
    }
    It 'passes the original ref name to the custom cleanup' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        function My-Func2() { }
        Mock -CommandName My-Func2 -Verifiable { }
        $mocks = Initialize-PreserveBranchCleanup

        Invoke-PreserveBranch { My-Func } -cleanup {
            $args[0] | Should -Be 'my-custom-branch'
            My-Func2
        }

        Should -Invoke -CommandName My-Func -Times 1
        Should -Invoke -CommandName My-Func2 -Times 1
        Invoke-VerifyMock $mocks -Times 1
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
        $mocks = Initialize-PreserveBranchCleanup

        { Invoke-PreserveBranch { My-Func } -onlyIfError } | Should -Throw

        Should -Invoke -CommandName My-Func -Times 1
        Invoke-VerifyMock $mocks -Times 1
    }


    It 'checks out the original commitish on a failure' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { throw 'error' }
        Initialize-NoCurrentBranch
        $mocks = Initialize-PreserveBranchCleanup -detachedHead 'baadf00d'

        { Invoke-PreserveBranch { My-Func } -onlyIfError } | Should -Throw

        Should -Invoke -CommandName My-Func -Times 1
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'skips the original cleanup but still runs the passed cleanup if the corresponding flag is passed' {
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { }
        function My-Func2() { }
        Mock -CommandName My-Func2 -Verifiable { }

        Initialize-NoCurrentBranch
        $mocks = Initialize-PreserveBranchCleanup -detachedHead 'baadf00d'

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
        $mocks = Initialize-PreserveBranchCleanup

        $result = Invoke-PreserveBranch { return My-Func }

        Should -Invoke -CommandName My-Func -Times 1
        Invoke-VerifyMock $mocks -Times 1
        $result | Should -Be $expectedResult
    }

    It 'checks out the original commitish when given a ResultWithCleanup result' {
        $expectedResult = 42
        function My-Func() { }
        Mock -CommandName My-Func -Verifiable { return New-ResultAfterCleanup $expectedResult }

        Initialize-NoCurrentBranch
        $mocks = Initialize-PreserveBranchCleanup -detachedHead 'baadf00d'

        $result = Invoke-PreserveBranch { return My-Func }

        Should -Invoke -CommandName My-Func -Times 1
        Invoke-VerifyMock $mocks -Times 1
        $result | Should -Be $expectedResult
    }

}