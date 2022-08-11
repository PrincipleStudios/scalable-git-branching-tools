BeforeAll {
    . $PSScriptRoot/Update-UpstreamBranch.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Update-UpstreamBranch' {
    It 'pushes a commit to the remote' {
        Mock git {
            throw "Unmocked git command: $args"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push github new-COMMIT:refs/heads/my-upstream' } { $global:LASTEXITCODE = 0 }

        Update-UpstreamBranch -commitish 'new-COMMIT' -config @{ remote = 'github'; upstreamBranch = 'my-upstream' }
    }
    It 'updates the local branch if no remote in config' {
        Mock git {
            throw "Unmocked git command: $args"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch my-upstream new-COMMIT -f' } { $global:LASTEXITCODE = 0 }

        Update-UpstreamBranch -commitish 'new-COMMIT' -config @{ remote = $nil; upstreamBranch = 'my-upstream' }
    }
}
