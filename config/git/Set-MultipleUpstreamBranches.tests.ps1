BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Update-UpstreamBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteTree.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-MultipleUpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-VerifyMock.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-MultipleUpstreamBranches.psm1"
    . $PSScriptRoot/../TestUtils.ps1

    Lock-InvokeWriteTree
}

Describe 'Set-MultipleUpstreamBranches' {
    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration -remote 'github' -upstreamBranchName 'my-upstream'
        }

        It 'sets the git file' {
            Initialize-FetchUpstreamBranch

            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream -q' } { 'upstream-HEAD' }
            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream^{tree} -q' } { 'upstream-TREE' }
            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'ls-tree upstream-TREE' } {
                "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore"
            }
            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } {
                'new-FILE'
            }
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter {
                $treeEntries -contains "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore" `
                    -AND $treeEntries -contains "100644 blob new-FILE`tfoobar"
            } { return 'new-TREE' }
            Mock git  -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'commit-tree new-TREE -m Add barbaz to foobar -p upstream-HEAD' } {
                'new-COMMIT'
            }

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
        }

        It 'provides mocks to do the same' {
            $mock = Initialize-SetMultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -commitMessage 'Add barbaz to foobar' -resultCommitish 'new-COMMIT'

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
            Invoke-VerifyMock $mock -Times 1
        }
    }

    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote -upstreamBranchName 'my-upstream'
        }

        It 'sets the git file' {
            Initialize-FetchUpstreamBranch

            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify my-upstream -q' } { 'upstream-HEAD' }
            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify my-upstream^{tree} -q' } { 'upstream-TREE' }
            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'ls-tree upstream-TREE' } {
                "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore"
            }
            Mock git -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } {
                'new-FILE'
            }
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter {
                $treeEntries -contains "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore" `
                    -AND $treeEntries -contains "100644 blob new-FILE`tfoobar"
            } { return 'new-TREE' }
            Mock git  -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'commit-tree new-TREE -m Add barbaz to foobar -p upstream-HEAD' } {
                'new-COMMIT'
            }

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
        }

        It 'provides mocks to do the same' {
            $mock = Initialize-SetMultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -commitMessage 'Add barbaz to foobar' -resultCommitish 'new-COMMIT'

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
            Invoke-VerifyMock $mock -Times 1
        }
    }
}
