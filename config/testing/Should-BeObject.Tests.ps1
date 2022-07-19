BeforeAll {
    . $PSScriptRoot/Should-BeObject.ps1
        
}

Describe 'Should-BeObject' {
    It 'recongizes $nil' {
        $nil | Should-BeObject $nil
    }
    It 'recongizes similar objects' {
        @{ name = 'Bob' } | Should-BeObject @{ name = 'Bob' }
        @{ name = 'Bob'; age = 35 } | Should-BeObject @{ name = 'Bob'; age = 35 }
    }
    
    It 'rejects dissimilar objects' {
        { @{ name = 'Bob' } | Should-BeObject @{ name = 'Bob'; age = 35 } } | Should -Throw
        { @{ name = 'Bob' } | Should-BeObject @{ name = 'Jim' } } | Should -Throw
        { @{ name = 'Bob'; age = 35 } | Should-BeObject @{ name = 'Bob' } } | Should -Throw
    }
    
    It 'rejects mismatched types' {
        { 'Bob' | Should-BeObject @{ name = 'Bob' } } | Should -Throw
    }
}
