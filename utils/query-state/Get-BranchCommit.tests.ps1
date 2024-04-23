BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-BranchCommit.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-BranchCommit.mocks.psm1"
}

Describe 'Get-BranchCommit' {
    It 'resolves a commit' {
        Initialize-GetBranchCommit 'foo' '1234567890'

        $result = Get-BranchCommit 'foo'
        $result | Should -Be '1234567890'
    }

    It 'resolve to null when unknown' {
        Initialize-GetBranchCommit 'foo' $null

        $result = Get-BranchCommit 'foo'
        $result | Should -Be $null
    }

    It 'resolves via an override' {
        $result = Get-BranchCommit 'foo' -commitMappingOverride @{
            baz = $null
            'foo' = '1234567890'
        }
        $result | Should -Be '1234567890'
    }
}
