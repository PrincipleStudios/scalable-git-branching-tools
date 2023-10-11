Describe 'local action "create-branch"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionCreateBranch.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }

    BeforeEach {
        $fw = Register-Framework -throwInsteadOfExit
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $output = $fw.assertDiagnosticOutput
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = $fw.diagnostics
    }

    function AddStandardTests() {
        It 'creates from a single branch' {
            Initialize-LocalActionCreateBranchSuccess @('baz') 'new-Commit' -mergeMessageTemplate "Merge {}"

            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "upstreamBranches": [
                        "baz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            $diag | Should -BeNullOrEmpty
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
        }

        It 'handles standard functionality' {
            $mocks = Initialize-LocalActionCreateBranchSuccess @('baz', 'barbaz') 'new-Commit' -mergeMessageTemplate "Merge {}"

            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            $diag | Should -Be $null
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'fails if all branches could not be resolved' {
            $mocks = Initialize-LocalActionCreateBranchSuccess @('baz', 'barbaz') 'new-Commit' `
                -mergeMessageTemplate "Merge {}" `
                -failAtMerge 0

            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            { Assert-Diagnostics $diag } | Should -Throw
            $output | Should -contain 'ERR:  No branches could be resolved to merge'
            $result | Assert-ShouldBeObject @{ commit = $null }
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
        }

        AddStandardTests
        
        It 'reports merge failures' {
            $mocks = Initialize-LocalActionCreateBranchSuccess @('baz', 'barbaz') 'new-Commit' `
                -mergeMessageTemplate "Merge {}" `
                -failAtMerge 1

            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            { Assert-Diagnostics $diag } | Should -Not -Throw
            $output | Should -contain 'WARN: Could not merge the following branches: barbaz'
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
            Invoke-VerifyMock $mocks -Times 1
        }
    }
    
    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration

            Initialize-AnyUpstreamBranches
            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/upgrade-dependencies')
            }
        }
        
        AddStandardTests
        
        It 'reports merge failures' {
            $mocks = Initialize-LocalActionCreateBranchSuccess @('baz', 'barbaz') 'new-Commit' `
                -mergeMessageTemplate "Merge {}" `
                -failAtMerge 1

            $result = Invoke-LocalAction ('{ 
                "type": "create-branch", 
                "parameters": {
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            { Assert-Diagnostics $diag } | Should -Not -Throw
            $output | Should -contain 'WARN: Could not merge the following branches: origin/barbaz'
            $result | Assert-ShouldBeObject @{ commit = 'new-COMMIT' }
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
