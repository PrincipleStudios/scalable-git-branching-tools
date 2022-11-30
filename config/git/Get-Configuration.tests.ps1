BeforeAll {
    . $PSScriptRoot/Get-Configuration.ps1
    . $PSScriptRoot/../TestUtils.ps1
    
    Mock git {
        throw "Unmocked git command: $args"
    }
}

Describe 'Get-Configuration' {

    It 'Defaults values' {
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'remote'}

        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.defaultServiceLine'}
        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-parse --verify main -q'} {
            'some-hash'
            $Global:LASTEXITCODE = 0
        }
        
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.upstreamBranch'}

        Get-Configuration | Should-BeObject @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' }
    }

    It 'Defaults values with no main branch' {
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'remote'}
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.defaultServiceLine'}
        Mock git {
            $global:LASTEXITCODE = 128
        } -ParameterFilter {($args -join ' ') -eq 'rev-parse --verify main -q'}
        
        
        Mock git {
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.upstreamBranch'}

        Get-Configuration | Should-BeObject @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = $nil }
    }

    It 'Defaults values with a remote main branch' {
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
        Mock git {
            'origin'
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'remote'}
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.defaultServiceLine'}
        Mock git {
            'some-hash'
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'rev-parse --verify origin/main -q'}
        
        
        Mock git {
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.upstreamBranch'}

        Get-Configuration | Should-BeObject @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = 'main' }
    }

    It 'Overrides defaults' {
        Mock git {
            "github"
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.remote'}
        
        Mock git {
            "upstream-config"
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.upstreamBranch'}
        
        Mock git {
            'trunk'
            $global:LASTEXITCODE = 0
        } -ParameterFilter {($args -join ' ') -eq 'config scaled-git.defaultServiceLine'}

        Get-Configuration | Should-BeObject @{ remote = 'github'; upstreamBranch = 'upstream-config'; defaultServiceLine = 'trunk' }
    }
}
