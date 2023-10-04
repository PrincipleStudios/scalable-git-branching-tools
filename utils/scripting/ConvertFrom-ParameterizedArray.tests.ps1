Describe 'ConvertFrom-ParameterizedArray' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedArray.psm1"
    }
    BeforeEach {
        Register-Framework
    }

    It 'can evaluate single parameters' {
        $params = @{ foo = 'bar' }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($params.foo)', 'baz') -config @{} -params $params -actions @{} -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Should -Be @('foo', 'bar', 'baz')
        $result.fail | Should -Be $false
    }

    It 'can evaluate array parameters' {
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($params.foo -join ",")') -config @{} -params $params -actions @{} -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Should -Be @('foo', 'bar', 'baz')
        $result.fail | Should -Be $false
    }

    It 'reports errors' {
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -config @{} -params $params -actions @{} -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true
    }

    It 'reports warnings if diagnostics are provided' {
        $diag = New-Diagnostics
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -config @{} -params $params -actions @{} -diagnostics $diag -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Not -Throw
        $output | Should -Be @('WARN: Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

    It 'reports errors if diagnostics are provided and flagged to fail on error' {
        $diag = New-Diagnostics
        $params = @{ foo = @('bar', 'baz') }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -config @{} -params $params -actions @{} -diagnostics $diag -failOnError -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Throw
        $output | Should -Be @('ERR:  Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

}
