BeforeAll {
    . "$PSScriptRoot/../core/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Assert-CleanWorkingDirectory.mocks.psm1"
}

Describe 'Assert-CleanWorkingDirectory' {
    It 'throws if exit code is non-zero' {
        Initialize-DirtyWorkingDirectory
        { Assert-CleanWorkingDirectory } | Should -Throw
    }
    It 'throws if non-ignored files exist' {
        Initialize-UntrackedFiles
        { Assert-CleanWorkingDirectory } | Should -Throw
    }
    It 'does not throw if exit code is 0 and no non-ignored files exist' {
        Initialize-CleanWorkingDirectory
        Assert-CleanWorkingDirectory
    }
}
