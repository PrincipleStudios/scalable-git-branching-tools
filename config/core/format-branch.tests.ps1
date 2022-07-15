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
}