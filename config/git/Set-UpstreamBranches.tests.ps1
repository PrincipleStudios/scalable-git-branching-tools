BeforeAll {
    . "$PSScriptRoot/../core/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.mocks.psm1"
    . $PSScriptRoot/Set-UpstreamBranches.ps1
    . $PSScriptRoot/../TestUtils.ps1

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/Invoke-WriteTree.ps1
    Mock -CommandName Invoke-WriteTree { throw "Unexpected parameters for Invoke-WriteTree: $treeEntries" }
}

Describe 'Set-UpstreamBranches' {
    It 'sets the git file' {
        Initialize-ToolConfiguration -remote 'github' -upstreamBranchName 'my-upstream'
        Initialize-FetchUpstreamBranch

        $config = @{ remote = 'github'; upstreamBranch = 'my-upstream' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream -q' } { 'upstream-HEAD' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream^{tree} -q' } { 'upstream-TREE' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'ls-tree upstream-TREE' } {
            "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore"
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } {
            'new-FILE'
        }
        Mock -CommandName Invoke-WriteTree -ParameterFilter {
            $treeEntries -contains "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore" `
                -AND $treeEntries -contains "100644 blob new-FILE`tfoobar"
        } { return 'new-TREE' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'commit-tree new-TREE -m Add barbaz to foobar -p upstream-HEAD' } {
            'new-COMMIT'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'push github new-COMMIT:refs/heads/my-upstream' } { $global:LASTEXITCODE = 0 }

        Set-UpstreamBranches -branchName 'foobar' -upstreamBranches @('baz', 'barbaz') -m 'Add barbaz to foobar' -config $config
    }
}
