BeforeAll {
    . "$PSScriptRoot/../core/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-GitFileNames.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-GitFileNames.mocks.psm1"
}

Describe 'Get-GitFileNames' {
    It 'lists the files in a shallow git tree of a local branch' {
        Initialize-GitFileNames 'some-branch' @("alpha.txt", "beta.txt", "readme.md")

        $result = Get-GitFileNames -branchName 'some-branch'

        $result | Should -Contain 'alpha.txt'
        $result | Should -Contain 'beta.txt'
        $result | Should -Contain 'readme.md'
    }

    It 'lists the files in a deep git tree of a local branch' {
        Initialize-GitFileNames 'some-branch' @("docs/alpha.txt", "docs/beta.txt", "readme.md")

        $result = Get-GitFileNames -branchName 'some-branch'

        $result | Should -Contain 'docs/alpha.txt'
        $result | Should -Contain 'docs/beta.txt'
        $result | Should -Contain 'readme.md'
        $result | Should -Not -Contain 'docs'
    }

    It 'lists the files in a shallow git tree of a remote branch' {
        Initialize-GitFileNames 'origin/some-branch' @("alpha.txt", "beta.txt", "readme.md")

        $result = Get-GitFileNames -branchName 'some-branch' -remote 'origin'

        $result | Should -Contain 'alpha.txt'
        $result | Should -Contain 'beta.txt'
        $result | Should -Contain 'readme.md'
    }
}
