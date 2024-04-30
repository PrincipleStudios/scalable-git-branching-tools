Describe 'ConvertFrom-ParameterizedArray' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedArray.psm1"
    }
    BeforeEach {
        $fw = Register-Framework
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
    }

    It 'can evaluate single parameters' {
        $params = @{ foo = 'bar' }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($params.foo)', 'baz') -variables $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Should -Be @('foo', 'bar', 'baz')
        $result.fail | Should -Be $false
    }

    It 'can evaluate array parameters' {
        $params = @{ foo = @('bar', 'baz') }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($params.foo -join ",")') -variables $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Should -Be @('foo', 'bar', 'baz')
        $result.fail | Should -Be $false
    }

    It 'reports errors' {
        $params = @{ foo = @('bar', 'baz') }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -variables $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true
    }

    It 'reports warnings if diagnostics are provided' {
        $params = @{ foo = @('bar', 'baz') }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -variables $variables -diagnostics $diag -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Not -Throw
        $output | Should -Be @('WARN: Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

    It 'reports errors if diagnostics are provided and flagged to fail on error' {
        $params = @{ foo = @('bar', 'baz') }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedArray @('foo', '$($config.upstreamBranch)') -variables $variables -diagnostics $diag -failOnError -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Throw
        $output | Should -Be @('ERR:  Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

}
