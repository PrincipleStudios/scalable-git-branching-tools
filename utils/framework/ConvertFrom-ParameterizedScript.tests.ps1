Describe 'ConvertFrom-ParameterizedScript' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedScript.psm1"
    }

    It 'can evaluate from params' {
        $params = @{ foo = 'bar' }
        $result = ConvertFrom-ParameterizedScript -script '$($params.foo)' -params $params -actions @{}
        $result | Should -Be 'bar'
    }

    It 'can evaluate from actions including quotes' {
        $actions = @{
            'create-branch' = @{
                outputs = @{
                    commit = 'baadf00d'
                }
            }
        }
        $result = ConvertFrom-ParameterizedScript -script '$($actions["create-branch"].outputs["commit"])' -params @{} -actions $actions
        $result | Should -Be 'baadf00d'
    }

    It 'returns null if accessing an action that does not exist' {
        $result = ConvertFrom-ParameterizedScript -script '$($actions["create-branch"].outputs["commit"])' -params @{} -actions @{}
        $result | Should -Be $null
    }

    It 'returns null if an error occurs' {
        $result = ConvertFrom-ParameterizedScript -script '$($config.upstreamBranch)' -params @{} -actions @{}
        $result | Should -Be $null
    }

}
