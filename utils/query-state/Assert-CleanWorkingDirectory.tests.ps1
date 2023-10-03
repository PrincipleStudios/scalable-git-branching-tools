BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.mocks.psm1"
}

Describe 'Assert-CleanWorkingDirectory' {
    BeforeEach {
        Register-Framework
    }

    It 'throws if exit code is non-zero' {
        $mocks = Initialize-DirtyWorkingDirectory
        { Assert-CleanWorkingDirectory } | Should -Throw
        Invoke-VerifyMock $mocks -Times 1
    }
    It 'throws if non-ignored files exist' {
        $mocks = Initialize-UntrackedFiles
        { Assert-CleanWorkingDirectory } | Should -Throw
        Invoke-VerifyMock $mocks -Times 1
    }
    It 'does not throw if exit code is 0 and no non-ignored files exist' {
        $mocks = Initialize-CleanWorkingDirectory
        Assert-CleanWorkingDirectory
        Invoke-VerifyMock $mocks -Times 1
    }
}
