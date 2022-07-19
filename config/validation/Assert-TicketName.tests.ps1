BeforeAll {
    . $PSScriptRoot/Assert-TicketName.ps1
}

Describe 'Assert-TicketName' {
    It 'returns successfully for a valid ticket' {
        { Assert-TicketName 'FOO-8412' } | Should -Not -Throw
    }
    
    It 'errors for an invalid ticket' {
        { Assert-TicketName 'FOO-' } | Should -Throw
    }
    
    It 'errors for empty strings' {
        { Assert-TicketName '' } | Should -Throw
    }
    
    It 'returns successfully for empty strings when flagged with optional' {
        { Assert-TicketName '' -optional } | Should -Not -Throw
    }
}