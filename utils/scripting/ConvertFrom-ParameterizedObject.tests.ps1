Describe 'ConvertFrom-ParameterizedObject' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
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
        $result = ConvertFrom-ParameterizedObject $target -params @{} -actions @{}
        $result | Should -Be $null
    }
    
    It 'reports warnings if diagnostics are provided' {
        $diag = New-Diagnostics
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = '$($params.banter)' }
        $result = ConvertFrom-ParameterizedObject $target -params @{} -actions @{} -diagnostics $diag
        $result | Should -Be $null

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Not -Throw
        $output.Count | Should -Be 2
        $output | Should -Contain 'WARN: Unable to evaluate script: ''$($params.foo)'''
        $output | Should -Contain 'WARN: Unable to evaluate script: ''$($params.banter)'''
    }

    It 'reports errors if diagnostics are provided and flagged to fail on error' {
        $diag = New-Diagnostics
        $target = @{ 'foo' = '$($params.foo)'; 'baz' = '$($params.banter)' }
        $result = ConvertFrom-ParameterizedObject $target -params @{} -actions @{} -diagnostics $diag -failOnError
        $result | Should -Be $null

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Throw
        $output.Count | Should -Be 2
        $output | Should -Contain @('ERR:  Unable to evaluate script: ''$($params.foo)''')
        $output | Should -Contain @('ERR:  Unable to evaluate script: ''$($params.banter)''')
    }

}
