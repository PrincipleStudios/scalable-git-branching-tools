Describe 'local action "merge-branches"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionMergeBranches.mocks.psm1"
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
            Initialize-LocalActionMergeBranchesSuccess @('baz') 'new-Commit' -mergeMessageTemplate "Merge {}"

            $result = Invoke-LocalAction ('{ 
                "type": "merge-branches", 
                "parameters": {
                    "upstreamBranches": [
                        "baz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            $diag | Should -BeNullOrEmpty
            $result | Assert-ShouldBeObject @{
                commit = 'new-COMMIT'
                hasChanges = $false
                successful = @('baz')
                failed = @()
            }
        }

        It 'handles standard functionality' {
            $mocks = Initialize-LocalActionMergeBranchesSuccess @('baz', 'barbaz') 'new-Commit' -mergeMessageTemplate "Merge {}"

            $result = Invoke-LocalAction ('{ 
                "type": "merge-branches", 
                "parameters": {
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            $diag | Should -Be $null
            $result | Assert-ShouldBeObject @{
                commit = 'new-COMMIT'
                hasChanges = $true
                successful = @('baz', 'barbaz')
                failed = @()
            }
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'fails if all branches could not be resolved' {
            $mocks = Initialize-LocalActionMergeBranchesSuccess @('baz', 'barbaz') 'new-Commit' `
                -mergeMessageTemplate "Merge {}" `
                -failAtMerge 0

            $result = Invoke-LocalAction ('{ 
                "type": "merge-branches", 
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
            $result | Assert-ShouldBeObject @{
                commit = $null
                hasChanges = $false
                successful = $null
                failed = @('baz', 'barbaz')
            }
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'can specify an additional source' {
            $mocks = Initialize-LocalActionMergeBranchesSuccess @('baz', 'barbaz') 'new-Commit' `
                -source 'foo' `
                -mergeMessageTemplate "Merge {}"

            $result = Invoke-LocalAction ('{ 
                "type": "merge-branches", 
                "parameters": {
                    "source": "foo",
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            $diag | Should -BeNullOrEmpty
            $result | Assert-ShouldBeObject @{
                commit = 'new-COMMIT'
                hasChanges = $true
                successful = @('baz', 'barbaz')
                failed = @()
            }
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'fails early if the source fails' {
            $mocks = Initialize-LocalActionMergeBranchesFailure @('baz', 'barbaz') -failures @('foo') -resultCommitish 'new-Commit' `
                -source 'foo' `
                -mergeMessageTemplate "Merge {}"

            $result = Invoke-LocalAction ('{ 
                "type": "merge-branches", 
                "parameters": {
                    "source": "foo",
                    "upstreamBranches": [
                        "baz",
                        "barbaz"
                    ],
                    "mergeMessageTemplate": "Merge {}"
                }
            }' | ConvertFrom-Json) -diagnostics $diag
            Invoke-FlushAssertDiagnostic $diag
            if ($null -ne (Get-Configuration).remote) {
                $output | Should -be @("ERR:  Could not resolve 'origin/foo' for source of merge")
            } else {
                $output | Should -be @("ERR:  Could not resolve 'foo' for source of merge")
            }
            $result | Assert-ShouldBeObject @{
                commit = $null
                hasChanges = $false
                successful = @()
                failed = @('foo')
            }
            Invoke-VerifyMock $mocks -Times 1
        }
    }
    
    Context 'without remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote

            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/upgrade-dependencies')
            }
        }

        AddStandardTests
        
        It 'reports merge failures' {
            $mocks = Initialize-LocalActionMergeBranchesSuccess @('baz', 'barbaz') 'new-Commit' `
                -mergeMessageTemplate "Merge {}" `
                -failAtMerge 1

            $result = Invoke-LocalAction ('{ 
                "type": "merge-branches", 
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
            $result | Assert-ShouldBeObject @{
                commit = 'new-COMMIT'
                hasChanges = $false
                successful = @('baz')
                failed = @('barbaz')
            }
            Invoke-VerifyMock $mocks -Times 1
        }
    }
    
    Context 'with remote' {
        BeforeEach {
            Initialize-ToolConfiguration

            Initialize-UpstreamBranches @{
                'feature/homepage-redesign' = @('infra/upgrade-dependencies')
            }
        }
        
        AddStandardTests
        
        It 'reports merge failures' {
            $mocks = Initialize-LocalActionMergeBranchesSuccess @('baz', 'barbaz') 'new-Commit' `
                -mergeMessageTemplate "Merge {}" `
                -failAtMerge 1

            $result = Invoke-LocalAction ('{ 
                "type": "merge-branches", 
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
            $result | Assert-ShouldBeObject @{
                commit = 'new-COMMIT'
                hasChanges = $false
                successful = @('baz')
                failed = @('barbaz')
            }
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
