BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.mocks.psm1"
}

Describe 'Get-CurrentBranch' {
    It 'returns what is initialized' {
        Initialize-CurrentBranch 'feature/FOO-1'
        Get-CurrentBranch | Should -Be 'feature/FOO-1'
    }
}
