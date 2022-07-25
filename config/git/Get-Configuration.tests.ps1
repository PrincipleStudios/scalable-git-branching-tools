BeforeAll {
    . $PSScriptRoot/Get-Configuration.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Get-Configuration' {

    It 'Defaults values' {
        Mock git {
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
        Mock git {
        } -ParameterFilter {($args -join ' ') -eq 'remote'}
        
        
        Mock git {
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.upstreamBranch'}

        Get-Configuration | Should-BeObject @{ remote = $nil; upstreamBranch = '_upstream' }
    }

    It 'Overrides defaults' {
        Mock git {
            Write-Output "github"
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
        
        Mock git {
            Write-Output "upstream-config"
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.upstreamBranch'}

        Get-Configuration | Should-BeObject @{ remote = 'github'; upstreamBranch = 'upstream-config' }
    }
}
