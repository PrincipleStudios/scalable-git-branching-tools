Describe 'ConvertFrom-ParameterizedString' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
    }

    It 'can evaluate from params' {
        $params = @{ foo = 'bar' }
        $result = ConvertFrom-ParameterizedString -script '$($params.foo)' -params $params -actions @{}
        $result.result | Should -Be 'bar'
        $result.fail | Should -Be $false
    }

    It 'can evaluate from actions including quotes' {
        $actions = @{
            'create-branch' = @{
                outputs = @{
                    commit = 'baadf00d'
                }
            }
        }
        $result = ConvertFrom-ParameterizedString -script '$($actions["create-branch"].outputs["commit"])' -params @{} -actions $actions
        $result.result | Should -Be 'baadf00d'
        $result.fail | Should -Be $false
    }

    It 'returns null if accessing an action that does not exist' {
        $result = ConvertFrom-ParameterizedString -script '$($actions["create-branch"].outputs["commit"])' -params @{} -actions @{}
        $result.result | Should -Be $null
        $result.fail | Should -Be $true
    }

    It 'returns null if an error occurs' {
        $result = ConvertFrom-ParameterizedString -script '$($config.upstreamBranch)' -params @{} -actions @{}
        $result.result | Should -Be $null
        $result.fail | Should -Be $true
    }

    It 'reports warnings if diagnostics are provided' {
        $diag = New-Diagnostics
        $result = ConvertFrom-ParameterizedString -script '$($config.upstreamBranch)' -params @{} -actions @{} -diagnostics $diag
        $result.result | Should -Be $null
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Not -Throw
        $output | Should -Be @('WARN: Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

    It 'reports errors if diagnostics are provided and flagged to fail on error' {
        $diag = New-Diagnostics
        $result = ConvertFrom-ParameterizedString -script '$($config.upstreamBranch)' -params @{} -actions @{} -diagnostics $diag -failOnError
        $result.result | Should -Be $null
        $result.fail | Should -Be $true

        $output = Register-Diagnostics -throwInsteadOfExit
        { Assert-Diagnostics $diag } | Should -Throw
        $output | Should -Be @('ERR:  Unable to evaluate script: ''$($config.upstreamBranch)''')
    }

}
