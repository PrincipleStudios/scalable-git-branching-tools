BeforeAll {
    . $PSScriptRoot/Get-Tickets.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Get-Tickets' {
    It 'handles a single ticket' {
        Get-Tickets @{ type = 'feature'; ticket = 'FOO-123' } | Should -Be @('FOO-123')
    }
    It 'handles multiple tickets ticket' {
        Get-Tickets @{ type = 'integration'; tickets = @('FOO-125', 'XYZ-1') } | Should -Be @('FOO-125', 'XYZ-1')
    }
    It 'handles no tickets' {
        Get-Tickets @{ type = 'service-line' } | Should -Be @()
    }
}
