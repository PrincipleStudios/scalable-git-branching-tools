Describe 'local action "set-upstream"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionSetUpstream.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        Register-Framework
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration -remote 'github' -upstreamBranchName 'my-upstream'
        }

        It 'sets the git file' {
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream -q' } { 'upstream-HEAD' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify github/my-upstream^{tree} -q' } { 'upstream-TREE' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'ls-tree upstream-TREE' } {
                "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore"
            }
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes("baz`nbarbaz`n")) 'new-FILE'
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore" `
                    -AND $treeEntries -contains "100644 blob new-FILE`tfoobar"
            } { return 'new-TREE' }
            Mock git  -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'commit-tree new-TREE -m Add barbaz to foobar -p upstream-HEAD' } {
                'new-COMMIT'
            }

            $diag = New-Diagnostics
            
            $result = Invoke-LocalAction @{
                type = 'set-upstream'
                parameters = @{
                    upstreamBranches = @{ foobar = @('baz'; 'barbaz') };
                    message = 'Add barbaz to foobar'
                }
            } -diagnostics $diag
            Register-Diagnostics -throwInsteadOfExit
            { Assert-Diagnostics $diag } | Should -Not -Throw
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
        }

        It 'provides mocks to do the same' {
            $mock = Initialize-LocalActionSetUpstream @{ 'foobar' = @('baz', 'barbaz') } -message 'Add barbaz to foobar' -commitish 'new-COMMIT'

            $diag = New-Diagnostics
            $result = Invoke-LocalAction @{
                type = 'set-upstream'
                parameters = @{
                    upstreamBranches = @{ foobar = @('baz', 'barbaz') };
                    message = 'Add barbaz to foobar'
                }
            } -diagnostics $diag
            Register-Diagnostics -throwInsteadOfExit
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
            Invoke-VerifyMock $mock -Times 1
        }

        It 'handles action deserialized from json' {
            $mock = Initialize-LocalActionSetUpstream @{ 'foobar' = @('baz', 'barbaz') } -message 'Add barbaz to foobar' -commitish 'new-COMMIT'

            $diag = New-Diagnostics
            $result = Invoke-LocalAction ('{ 
                "type": "set-upstream", 
                "parameters": {
                    "message": "Add barbaz to foobar",
                    "upstreamBranches": {
                        "foobar": [
                            "baz",
                            "barbaz"
                        ]
                    }
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            Register-Diagnostics -throwInsteadOfExit
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
            Invoke-VerifyMock $mock -Times 1
        }

        # It 'allows the mock to not provide the commit message' {
        #     $mock = Initialize-SetMultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -commitish 'new-COMMIT'

        #     $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
        #     $result | Should -Be 'new-COMMIT'
        #     Invoke-VerifyMock $mock -Times 1
        # }

        # It 'allows the mock to not provide the files' {
        #     $mock = Initialize-SetMultipleUpstreamBranches -commitMessage 'Add barbaz to foobar' -commitish 'new-COMMIT'

        #     $result = Set-MultipleUpstreamBranches @{ 'foobar' = @('baz', 'barbaz') } -m 'Add barbaz to foobar'
        #     $result | Should -Be 'new-COMMIT'
        #     Invoke-VerifyMock $mock -Times 1
        # }
    }

    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote -upstreamBranchName 'my-upstream'
        }

        It 'sets the git file' {
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify my-upstream -q' } { 'upstream-HEAD' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify my-upstream^{tree} -q' } { 'upstream-TREE' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'ls-tree upstream-TREE' } {
                "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore"
            }
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes("baz`nbarbaz`n")) 'new-FILE'
            Initialize-WriteTree @(
                "100644 blob 2adfafd75a2c423627081bb19f06dca28d09cd8e`t.dockerignore",
                "100644 blob new-FILE`tfoobar"
            ) 'new-TREE'
            Mock git  -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'commit-tree new-TREE -m Add barbaz to foobar -p upstream-HEAD' } {
                'new-COMMIT'
            }

            $diag = New-Diagnostics
            $result = Invoke-LocalAction @{
                type = 'set-upstream'
                parameters = @{
                    upstreamBranches = @{ foobar = @('baz', 'barbaz') };
                    message = 'Add barbaz to foobar'
                }
            } -diagnostics $diag
            Register-Diagnostics -throwInsteadOfExit
            { Assert-Diagnostics $diag } | Should -Not -Throw
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
        }
    }
}
