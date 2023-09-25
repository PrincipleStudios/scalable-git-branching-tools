Describe 'ConvertFrom-ParameterizedAnything' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedAnything.psm1"
    }
    BeforeEach {
        Register-Framework
    }

    It 'can evaluate parameters in objects nested in arrays' {
        $target = @('foo', @{ '$($params.foo)' = '$($params.baz)' })
        $params = @{ foo = 'bar'; baz = 'woot' }
        $result = ConvertFrom-ParameterizedAnything $target -params $params -actions @{} -failOnError
        $result.result.Count | Should -Be 2
        $result.result[0] | Should -Be 'foo'
        $result.result[1] | Assert-ShouldBeObject @{ 'bar'= 'woot' }
    }

    It 'can evaluate parameters in arrays nested in objects' {
        $target = @{ 'foo' = @('$($params.foo -join ",")', '$($params.banter)'); 'baz' = '$($params.banter)' }
        $params = @{ foo = @('bar', 'baz'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = @('bar', 'baz', 'woot'); 'baz' = 'woot' }
    }
    
    
    It 'can evaluate parameters in objects nested in arrays when converting from json' {
        $target = @('foo', @{ '$($params.foo)' = '$($params.baz)' })
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = 'bar'; baz = 'woot' }
        $result = ConvertFrom-ParameterizedAnything $target -params $params -actions @{} -failOnError
        $result.result.Count | Should -Be 2
        $result.result[0] | Should -Be 'foo'
        $result.result[1] | Assert-ShouldBeObject @{ 'bar'= 'woot' }
    }

    It 'can evaluate parameters in arrays nested in objects' {
        $target = @{ 'foo' = @('$($params.foo -join ",")', '$($params.banter)'); 'baz' = '$($params.banter)' }
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = @('bar', 'baz'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = @('bar', 'baz', 'woot'); 'baz' = 'woot' }
    }
    
}
