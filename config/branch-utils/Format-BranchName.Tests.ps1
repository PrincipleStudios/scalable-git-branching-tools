BeforeAll {
    . $PSScriptRoot/Format-BranchName.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'Format-BranchName' {
    It 'Formats service line branches properly' {
        Format-BranchName 'main' | Should -Be 'main'
    }
    It 'Formats RC branches properly' {
        Format-BranchName 'rc' @() '2022-07-14' | Should -Be 'rc/2022-07-14'
        Format-BranchName 'rc' @('FOO-123') '2022-07-14' | Should -Be 'rc/2022-07-14'

        # Throws if there is no comment
        { Format-BranchName 'rc' @() '' } | Should -Throw
    }
    It 'Formats feature branches properly' {
        Format-BranchName 'feature' @('FOO-123') | Should -Be 'feature/FOO-123'
        Format-BranchName 'feature' @('FOO-123') "some comment" | Should -Be 'feature/FOO-123-some-comment'
        Format-BranchName 'feature' @('FOO-123', 'FOO-124') | Should -Be 'feature/FOO-123_FOO-124'
        Format-BranchName 'feature' @('FOO-123', 'FOO-124') "some comment" | Should -Be 'feature/FOO-123_FOO-124-some-comment'
        Format-BranchName 'bugfix' @('FOO-123') | Should -Be 'bugfix/FOO-123'
        
        # Throws if there is no ticket
        { Format-BranchName 'feature' @() 'some-comment' } | Should -Throw
        { Format-BranchName 'bugfix' @() 'some-comment' } | Should -Throw
    }
    It 'Formats integration branches properly' {
        Format-BranchName 'integration' @('FOO-124', 'XYZ-1') 'comment ignored' | Should -Be 'integrate/FOO-124_XYZ-1'
    }
    It 'Formats infrastructure branches properly' {
        Format-BranchName 'infra' @('XYZ-1') 'service update' | Should -Be 'infra/XYZ-1-service-update'

        # Throws if there is no comment
        { Format-BranchName 'infra' @() '' } | Should -Throw
    }
}
