Describe 'ConvertFrom-ParameterizedArray' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedArray.psm1"
    }

    It 'can evaluate single parameters' {
        $params = @{ foo = 'bar' }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($params.foo)', 'baz') -params $params -actions @{}
        $result | Should -Be @('foo', 'bar', 'baz')
    }

    It 'can evaluate array parameters' {
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($params.foo -join ",")') -params $params -actions @{}
        $result | Should -Be @('foo', 'bar', 'baz')
    }

    It 'reports errors by returning null' {
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -params $params -actions @{}
        $result | Should -Be $null
    }

}
