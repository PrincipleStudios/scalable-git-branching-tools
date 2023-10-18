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
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result.Count | Should -Be 2
        $result.result[0] | Should -Be 'foo'
        $result.result[1] | Assert-ShouldBeObject @{ 'bar'= 'woot' }
    }

    It 'can evaluate parameters in objects nested in arrays without extra syntax' {
        $target = @('foo', @{ '$params.foo' = '$params.baz' })
        $params = @{ foo = 'bar'; baz = 'woot' }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result.Count | Should -Be 2
        $result.result[0] | Should -Be 'foo'
        $result.result[1] | Assert-ShouldBeObject @{ 'bar'= 'woot' }
    }

    It 'can evaluate parameters in arrays nested in objects' {
        $target = @{ 'foo' = @('$($params.foo -join ",")', '$($params.banter)'); 'baz' = '$($params.banter)' }
        $params = @{ foo = @('bar', 'baz'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = @('bar', 'baz', 'woot'); 'baz' = 'woot' }
    }
    
    It 'can evaluate parameters in arrays nested in objects without extra syntax' {
        $target = @{ 'foo' = @('$params.foo', '$params.banter'); 'baz' = '$params.banter' }
        $params = @{ foo = @('bar', 'baz'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = @('bar', 'baz', 'woot'); 'baz' = 'woot' }
    }
    
    It 'can evaluate parameters in single-element-arrays nested in objects without extra syntax' {
        $target = @{ 'foo' = @('$params.foo'); 'baz' = '$params.banter' }
        $params = @{ foo = @('bar'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = @('bar'); 'baz' = 'woot' }
    }
    
    It 'can evaluate parameters in empty arrays nested in objects without extra syntax' {
        $target = @{ 'foo' = @('$params.foo'); 'baz' = '$params.banter' }
        $params = @{ foo = @(); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = @(); 'baz' = 'woot' }
    }
    
    It 'can evaluate single-element arrays as arrays' {
        $target = @('$params.foo')
        $params = @{ foo = @('bar'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result.Count | Should -Be 1
        Should -ActualValue $result.result -Be @('bar')
    }
    
    It 'can evaluate complex strings' {
        $target = '$($params.foo) and $($params.baz)'
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = 'bar'; baz = 'woot' }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Should -Be 'bar and woot'
    }
    
    It 'blocks poorly formatted strings' {
        $target = '$params.foo and $params.baz'
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = 'bar'; baz = 'woot' }
        { ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError } | Should -Throw
    }
    
    It 'can evaluate basic strings' {
        $target = '$params.foo'
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = 'bar'; baz = 'woot' }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Should -Be 'bar'
    }
    
    It 'can evaluate parameters in objects nested in arrays when converting from json' {
        $target = @('foo', @{ '$($params.foo)' = '$($params.baz)' })
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = 'bar'; baz = 'woot' }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result.Count | Should -Be 2
        $result.result[0] | Should -Be 'foo'
        $result.result[1] | Assert-ShouldBeObject @{ 'bar'= 'woot' }
    }

    It 'can evaluate parameters in arrays nested in objects when converting from json' {
        $target = @{ 'foo' = @('$($params.foo -join ",")', '$($params.banter)'); 'baz' = '$($params.banter)' }
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = @('bar', 'baz'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = @('bar', 'baz', 'woot'); 'baz' = 'woot' }
    }
    
    It 'preserve boolean JSON types' {
        $target = @{ 'foo' = $true; 'bar' = $false }
        $target = $target | ConvertTo-Json | ConvertFrom-Json
        $params = @{ }
        $result = ConvertFrom-ParameterizedAnything $target -config @{} -params $params -actions @{} -failOnError
        $result.result | Assert-ShouldBeObject @{ 'foo' = $true; 'bar' = $false }
    }
    
}
