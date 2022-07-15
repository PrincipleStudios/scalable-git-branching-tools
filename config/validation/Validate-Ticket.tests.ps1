BeforeAll {
    . $PSScriptRoot/validate-ticket.ps1
}

Describe 'Validate-Ticket' {
    It 'returns successfully for a valid ticket' {
        { Validate-Ticket 'FOO-8412' } | Should -Not -Throw
    }
    
    It 'errors for an invalid ticket' {
        { Validate-Ticket 'FOO-' } | Should -Throw
    }
    
    It 'errors for empty strings' {
        { Validate-Ticket '' } | Should -Throw
    }
    
    It 'returns successfully for empty strings when flagged with optional' {
        { Validate-Ticket '' -optional } | Should -Not -Throw
    }
}