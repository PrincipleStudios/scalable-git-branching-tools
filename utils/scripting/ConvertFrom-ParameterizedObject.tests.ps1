Describe 'ConvertFrom-ParameterizedObject' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedObject.psm1"
    }
    
    BeforeEach {
        $fw = Register-Framework
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
    }

    It 'ignores non-parameterized objects' {
        $target = @{ 'foo' = 'bar'; 'baz' = 'woot' }
        $params = @{ foo = 'bar' }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Assert-ShouldBeObject @{ 'foo' = 'bar'; 'baz' = 'woot' }
        $result.fail | Should -Be $false
    }

    It 'can evaluate value parameters' {
        $params = @{ foo = @('bar', 'baz') }
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = 'woot' }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Assert-ShouldBeObject @{ 'foo' = 'bar baz'; 'baz' = 'woot' }
        $result.fail | Should -Be $false
    }

    It 'can evaluate key parameters' {
        $target = @{ 'foo' = 'bar baz'; '$($params.banter)' = 'woot' }
        $params = @{ banter = 'baz' }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Assert-ShouldBeObject @{ 'foo' = 'bar baz'; 'baz' = 'woot' }
        $result.fail | Should -Be $false
    }

    It 'can evaluate key and value parameters' {
        $target = @{ 'foo' = '$($params.foo)'; '$($params.banter)' = 'woot' }
        $params = @{ foo = @('bar', 'baz'); banter = 'baz' }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Assert-ShouldBeObject @{ 'foo' = 'bar baz'; 'baz' = 'woot' }
        $result.fail | Should -Be $false
    }

    It 'can evaluate key and value parameters when loaded from JSON' {
        $target = @{ 'foo' = '$($params.foo)'; '$($params.banter)' = 'woot' } | ConvertTo-Json | ConvertFrom-Json
        $params = @{ foo = @('bar', 'baz'); banter = 'baz' }
        $variables = @{ config=@{}; params=$params; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.result | Assert-ShouldBeObject @{ 'foo' = 'bar baz'; 'baz' = 'woot' }
        $result.fail | Should -Be $false
    }

    It 'reports errors' {
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = '$($params.banter)' }
        $variables = @{ config=@{}; params=@{}; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target -variables $variables -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true
    }
    
    It 'reports warnings if diagnostics are provided' {
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = '$($params.banter)' }
        $variables = @{ config=@{}; params=@{}; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target -variables $variables -diagnostics $diag -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Not -Throw
        $output.Count | Should -Be 2
        $output | Should -Contain 'WARN: Unable to evaluate script: ''$($params.foo)'''
        $output | Should -Contain 'WARN: Unable to evaluate script: ''$($params.banter)'''
    }

    It 'reports errors if diagnostics are provided and flagged to fail on error' {
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = '$($params.banter)' }
        $variables = @{ config=@{}; params=@{}; actions=@{} }
        $result = ConvertFrom-ParameterizedObject $target -variables $variables -diagnostics $diag -failOnError -convertFromParameterized ${function:ConvertFrom-ParameterizedString}
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Throw
        $output.Count | Should -Be 2
        $output | Should -Contain @('ERR:  Unable to evaluate script: ''$($params.foo)''')
        $output | Should -Contain @('ERR:  Unable to evaluate script: ''$($params.banter)''')
    }

}
