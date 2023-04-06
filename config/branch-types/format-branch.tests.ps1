BeforeAll {
    . $PSScriptRoot/format-branch.ps1
}

Describe 'Format-Branch' {
    It 'formats a feature branch with a single ticket' {
        Format-Branch 'feature' @('FOO-8412') | Should -BeExactly 'feature/FOO-8412'
    }
    
    It 'formats a feature branch with a single ticket and description' {
        Format-Branch 'feature' @('FOO-8412') -m '@Services: update API' | Should -BeExactly 'feature/FOO-8412-services-update-api'
    }
    
    It 'formats a feature branch with a multiple tickets' {
        Format-Branch 'feature' @('FOO-8412', 'foo-8413') | Should -BeExactly 'feature/FOO-8412_FOO-8413'
    }
    
    It 'formats a feature branch with a multiple tickets and description' {
        Format-Branch 'feature' @('FOO-8412', 'foo-8413') -m '@Services: documentation' | Should -BeExactly 'feature/FOO-8412_FOO-8413-services-documentation'
    }

    It 'formats a release candidate branch' {
        Format-Branch 'rc' -m '2022-07-14' | Should -BeExactly 'rc/2022-07-14'
        Format-Branch 'rc' -m '2022-07-14.1' | Should -BeExactly 'rc/2022-07-14.1'
    }

    It 'formats integration branches' {
        Format-Branch 'integrate' @('ABC-1234','ABC-1235') | Should -BeExactly 'integrate/ABC-1234_ABC-1235'
        Format-Branch 'integrate' @('ABC-1234','ABC-1235','XYZ-78') | Should -BeExactly 'integrate/ABC-1234_ABC-1235_XYZ-78'
    }

    It 'formats a hotfix branch with a single ticket' {
        Format-Branch 'hotfix' @('FF-2') | Should -BeExactly 'hotfix/FF-2'
        Format-Branch 'hotfix' @('FF-3') -m 'Fix DB pooling' | Should -BeExactly 'hotfix/FF-3-fix-db-pooling'
    }
    
    It 'formats an infrastructure branch' {
        Format-Branch 'infra' -m 'Button Component' | Should -BeExactly 'infra/button-component'
        Format-Branch 'infra' -m 'Refactor Plugin API' | Should -BeExactly 'infra/refactor-plugin-api'
        Format-Branch 'infra' -m 'Update TypeScript' | Should -BeExactly 'infra/update-typescript'
    }
}