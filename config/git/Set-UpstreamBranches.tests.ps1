BeforeAll {
    . $PSScriptRoot/Set-UpstreamBranches.ps1
    . $PSScriptRoot/Get-Configuration.ps1
    . $PSScriptRoot/../TestUtils.ps1

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/Invoke-WriteTree.ps1
    Mock -CommandName Invoke-WriteTree { throw "Unexpected parameters for Invoke-WriteTree: $treeEntries" }
}

Describe 'Set-UpstreamBranches' {
    It 'sets the git file' {
        Mock git {
            throw "Unmocked git command: $args"
        }

        Mock -CommandName Get-Configuration { return @{ remote = 'github'; upstreamBranch = 'my-upstream' } }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch github my-upstream' } { $global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream -q' } { 'upstream-HEAD' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream^{tree} -q' } { 'upstream-TREE' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'ls-tree upstream-TREE' } { 
            "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore"
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } { 
            'new-FILE'
        }
        Mock -CommandName Invoke-WriteTree -ParameterFilter {
            $treeEntries[0] -eq "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore" `
                -AND $treeEntries[1] -eq "100644 blob new-FILE`tfoobar"
        } { return 'new-TREE' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'commit-tree new-TREE -m Add barbaz to foobar -p upstream-HEAD' } { 
            'new-COMMIT'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'push github new-COMMIT:refs/heads/my-upstream' } { $global:LASTEXITCODE = 0 }

        Set-UpstreamBranches -branchName 'foobar' -upstreamBranches @('baz', 'barbaz') -m 'Add barbaz to foobar'
    }
}
