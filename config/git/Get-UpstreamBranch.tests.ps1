BeforeAll {
    . $PSScriptRoot/Get-UpstreamBranch.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Get-UpstreamBranch' {
    It 'computes the upstream tracking branch name' {
        Mock git {
            throw "Unmocked git command: $args"
        }

        Get-UpstreamBranch -config @{ remote = 'github'; upstreamBranch = 'my-upstream' } | Should -Be 'github/my-upstream'
    }
    It 'can handle no remote' {
        Mock git {
            throw "Unmocked git command: $args"
        }

        Get-UpstreamBranch -config @{ remote = $nil; upstreamBranch = 'my-upstream' } | Should -Be 'my-upstream'
    }
    It 'fetches if requested' {
        Mock git {
            throw "Unmocked git command: $args"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch github my-upstream' } -Verifiable { $global:LASTEXITCODE = 0 }

        Get-UpstreamBranch -config @{ remote = 'github'; upstreamBranch = 'my-upstream' } -fetch | Should -Be 'github/my-upstream'
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'fetch github my-upstream' } -Times 1
    }
}
