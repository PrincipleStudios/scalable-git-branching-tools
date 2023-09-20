
Describe 'Assert-ShouldBeObject' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/Assert-ShouldBeObject.psm1"
    }

    It 'recongizes $nil' {
        $nil | Assert-ShouldBeObject $nil
    }
    It 'recongizes similar objects' {
        @{ name = 'Bob' } | Assert-ShouldBeObject @{ name = 'Bob' }
        @{ name = 'Bob'; age = 35 } | Assert-ShouldBeObject @{ name = 'Bob'; age = 35 }
    }

    It 'rejects dissimilar objects' {
        { @{ name = 'Bob' } | Assert-ShouldBeObject @{ name = 'Bob'; age = 35 } } | Should -Throw
        { @{ name = 'Bob' } | Assert-ShouldBeObject @{ name = 'Jim' } } | Should -Throw
        { @{ name = 'Bob'; age = 35 } | Assert-ShouldBeObject @{ name = 'Bob' } } | Should -Throw
    }

    It 'rejects mismatched types' {
        { 'Bob' | Assert-ShouldBeObject @{ name = 'Bob' } } | Should -Throw
    }

    It 'recongizes different types for arrays on properties' {
        { @{ names = @('Bob','Jim') } | Assert-ShouldBeObject @{ names = 'Bob Jim' } } | Should -Throw
        { @{ names = @('Bob','Jim') } | Should -Be @{ names = 'Bob Jim' } } | Should -Throw
    }
}
