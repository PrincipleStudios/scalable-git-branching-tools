Describe 'ConvertFrom-ParameterizedObject' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedObject.psm1"
    }

    It 'ignores non-parameterized objects' {
        $target = @{ 'foo' = 'bar'; 'baz' = 'woot' }
        $params = @{ foo = 'bar' }
        $result = ConvertFrom-ParameterizedObject $target -params $params -actions @{}
        $result | Assert-ShouldBeObject @{ 'foo' = 'bar'; 'baz' = 'woot' }
    }

    It 'can evaluate value parameters' {
        $params = @{ foo = @('bar', 'baz') }
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = 'woot' }
        $result = ConvertFrom-ParameterizedObject $target -params $params -actions @{}
        $result | Assert-ShouldBeObject @{ 'foo' = 'bar baz'; 'baz' = 'woot' }
    }

    It 'can evaluate key parameters' {
        $target = @{ 'foo' = 'bar baz'; 'baz' = '$($params.banter)' }
        $params = @{ banter = @('woot') }
        $result = ConvertFrom-ParameterizedObject $target -params $params -actions @{}
        $result | Assert-ShouldBeObject @{ 'foo' = 'bar baz'; 'baz' = 'woot' }
    }

    It 'can evaluate key and value parameters' {
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = '$($params.banter)' }
        $params = @{ foo = @('bar', 'baz'); banter = @('woot') }
        $result = ConvertFrom-ParameterizedObject $target -params $params -actions @{}
        $result | Assert-ShouldBeObject @{ 'foo' = 'bar baz'; 'baz' = 'woot' }
    }

    It 'reports errors by returning null' {
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = '$($params.banter)' }
        $params = @{ }
        $result = ConvertFrom-ParameterizedObject $target -params $params -actions @{}
        $result | Should -Be $null
    }
}
