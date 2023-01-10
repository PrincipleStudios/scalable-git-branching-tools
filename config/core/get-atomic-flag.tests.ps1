BeforeAll {
    . $PSScriptRoot/get-atomic-flag.ps1
}

Describe 'Get-AtomicFlag' {
    It 'Returns atomic flag when enabled' {
        Get-AtomicFlag $true | Should -BeExactly '--atomic'
    }
    It 'Returns empty when disabled' {
        Get-AtomicFlag $false | Should -BeExactly ''
    }
}