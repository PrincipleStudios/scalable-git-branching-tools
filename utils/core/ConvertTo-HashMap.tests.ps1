BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/ConvertTo-HashMap.psm1"
    . $PSScriptRoot/../../config/TestUtils.ps1
}

Describe 'ConvertTo-HashMap' {
    It 'hashes without any props' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap
            | Should-BeObject @{ 'abba' = 'abba'; 'bacca' = 'bacca'; 'cabba' = 'cabba' }
    }
    It 'hashes with a key selector' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap { $_[0] }
            | Should-BeObject @{ a = 'abba'; b = 'bacca'; c = 'cabba' }
    }
    It 'hashes with a key selector parameter' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap -getKey { $_[0] }
            | Should-BeObject @{ a = 'abba'; b = 'bacca'; c = 'cabba' }
    }
    It 'hashes with a value selector only' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap -getValue { $_[1..($_.length - 1)] -join '' }
            | Should-BeObject @{ 'abba' = 'bba'; 'bacca' = 'acca'; 'cabba' = 'abba' }
    }
    It 'hashes with a key and a value selector' {
        @('abba';'bacca';'cabba') | ConvertTo-HashMap { $_[0] } { $_[1..($_.length - 1)] -join '' }
            | Should-BeObject @{ 'a' = 'bba'; 'b' = 'acca'; 'c' = 'abba' }
    }
}