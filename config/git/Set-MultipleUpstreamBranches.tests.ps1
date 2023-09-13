BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../../utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Update-UpstreamBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-MultipleUpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-VerifyMock.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Set-MultipleUpstreamBranches.psm1"
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Set-MultipleUpstreamBranches' {
    BeforeEach {
        Register-Framework
    }
    
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
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes("baz`nbarbaz`n")) 'new-FILE'
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
            $mock = Initialize-SetMultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -commitMessage 'Add barbaz to foobar' -commitish 'new-COMMIT'

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
            Invoke-VerifyMock $mock -Times 1
        }

        It 'allows the mock to not provide the commit message' {
            $mock = Initialize-SetMultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -commitish 'new-COMMIT'

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
            Invoke-VerifyMock $mock -Times 1
        }

        It 'allows the mock to not provide the files' {
            $mock = Initialize-SetMultipleUpstreamBranches -commitMessage 'Add barbaz to foobar' -commitish 'new-COMMIT'

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
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes("baz`nbarbaz`n")) 'new-FILE'
            Initialize-WriteTree @(
                "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore",
                "100644 blob new-FILE`tfoobar"
            ) 'new-TREE'
            Mock git  -ModuleName 'Set-MultipleUpstreamBranches' -ParameterFilter { ($args -join ' ') -eq 'commit-tree new-TREE -m Add barbaz to foobar -p upstream-HEAD' } {
                'new-COMMIT'
            }

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
        }

        It 'provides mocks to do the same' {
            $mock = Initialize-SetMultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -commitMessage 'Add barbaz to foobar' -commitish 'new-COMMIT'

            $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
            $result | Should -Be 'new-COMMIT'
            Invoke-VerifyMock $mock -Times 1
        }
    }
}
