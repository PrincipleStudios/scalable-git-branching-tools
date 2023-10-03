Describe 'local action "create-branch"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionCreateBranch.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }

    function AddStandardTests() {
        It 'halts if the working directory is not clean' {
            Initialize-DirtyWorkingDirectory

            $output = Register-Diagnostics -throwInsteadOfExit
            $result = Invoke-LocalAction ('{ 
                    "type": "create-branch", 
                    "parameters": {
                        "target": "foobar",
                        "upstreamBranches": [
                            "baz",
                            "barbaz"
                        ]
                    }
                }' | ConvertFrom-Json) -diagnostics $diag
            $result | Should -Be $null
            { Assert-Diagnostics $diag } | Should -Throw
            $output | Should -Contain 'ERR:  Git working directory is not clean.'
        }

        It 'creates from a single branch' {
            Initialize-LocalActionCreateBranchSuccess 'foobar' @('baz') 'new-Commit'

            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "target": "foobar",
                    "upstreamBranches": [
                        "baz"
                    ]
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            $diag | Should -Be $null
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
        }

        It 'handles standard functionality' {
            $mocks = Initialize-LocalActionCreateBranchSuccess 'foobar' @('baz', 'barbaz') 'new-Commit'

            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "target": "foobar",
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ]
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            $diag | Should -Be $null
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'reports merge failures' {
            $mocks = Initialize-LocalActionCreateBranchSuccess 'foobar' @('baz', 'barbaz') 'new-Commit' `
                -failAtMerge 1

            $output = Register-Diagnostics -throwInsteadOfExit
            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "target": "foobar",
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ]
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            { Assert-Diagnostics $diag } | Should -Throw
            $output | Should -contain 'ERR:  Failed to merge all branches'
            $result | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }
    }
    
    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote

            Initialize-AnyUpstreamBranches
            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/upgrade-dependencies')
            }
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $diag = New-Diagnostics
        }

        AddStandardTests
    }
    
    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration

            Initialize-AnyUpstreamBranches
            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/upgrade-dependencies')
            }
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $diag = New-Diagnostics
        }
        
        AddStandardTests
    }
}
