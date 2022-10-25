BeforeAll {
    . $PSScriptRoot/ArrayToHash.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'ArrayToHash' {
    It 'hashes without any props' {
        @('abba';'bacca';'cabba') | ArrayToHash
            | Should-BeObject @{ 'abba' = 'abba'; 'bacca' = 'bacca'; 'cabba' = 'cabba' }
    }
    It 'hashes with a key selector' {
        @('abba';'bacca';'cabba') | ArrayToHash { $_[0] }
            | Should-BeObject @{ a = 'abba'; b = 'bacca'; c = 'cabba' }
    }
    It 'hashes with a key selector parameter' {
        @('abba';'bacca';'cabba') | ArrayToHash -getKey { $_[0] }
            | Should-BeObject @{ a = 'abba'; b = 'bacca'; c = 'cabba' }
    }
    It 'hashes with a value selector only' {
        @('abba';'bacca';'cabba') | ArrayToHash -getValue { $_[1..($_.length - 1)] -join '' }
            | Should-BeObject @{ 'abba' = 'bba'; 'bacca' = 'acca'; 'cabba' = 'abba' }
    }
    It 'hashes with a key and a value selector' {
        @('abba';'bacca';'cabba') | ArrayToHash { $_[0] } { $_[1..($_.length - 1)] -join '' }
            | Should-BeObject @{ 'a' = 'bba'; 'b' = 'acca'; 'c' = 'abba' }
    }
}