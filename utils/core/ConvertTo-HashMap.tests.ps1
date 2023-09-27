BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
    Import-Module -Scope Local "$PSScriptRoot/ConvertTo-HashMap.psm1"
}

Describe 'ConvertTo-HashMap' {
    It 'hashes without any props' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap
            | Assert-ShouldBeObject @{ 'abba' = 'abba'; 'bacca' = 'bacca'; 'cabba' = 'cabba' }
    }
    It 'hashes with a key selector' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap { $_[0] }
            | Assert-ShouldBeObject @{ a = 'abba'; b = 'bacca'; c = 'cabba' }
    }
    It 'hashes with a key selector parameter' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap -getKey { $_[0] }
            | Assert-ShouldBeObject @{ a = 'abba'; b = 'bacca'; c = 'cabba' }
    }
    It 'hashes with a value selector only' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap -getValue { $_[1..($_.length - 1)] -join '' }
            | Assert-ShouldBeObject @{ 'abba' = 'bba'; 'bacca' = 'acca'; 'cabba' = 'abba' }
    }
    It 'hashes with a key and a value selector' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap { $_[0] } { $_[1..($_.length - 1)] -join '' }
            | Assert-ShouldBeObject @{ 'a' = 'bba'; 'b' = 'acca'; 'c' = 'abba' }
    }
}