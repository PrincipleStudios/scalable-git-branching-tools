Describe 'ConvertFrom-ParameterizedArray' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedArray.psm1"
    }
    BeforeEach {
        Register-Framework
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

    It 'reports warnings if diagnostics are provided' {
        $diag = New-Diagnostics
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -params $params -actions @{} -diagnostics $diag
        $result | Should -Be $null

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Not -Throw
        $output | Should -Be @('WARN: Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

    It 'reports errors if diagnostics are provided and flagged to fail on error' {
        $diag = New-Diagnostics
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -params $params -actions @{} -diagnostics $diag -failOnError
        $result | Should -Be $null

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Throw
        $output | Should -Be @('ERR:  Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

}
