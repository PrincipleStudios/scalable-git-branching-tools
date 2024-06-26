Describe 'Invoke-PruneAudit' {
    BeforeAll {
        . "$PSScriptRoot/utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"
        
        function Initialize-ValidDownstreamBranchNames {
            $upstreams = Select-AllUpstreamBranches
            [string[]]$entries = @()
            foreach ($key in $upstreams.Keys) {
                foreach ($downstream in $upstreams[$key]) {
                    if ($downstream -notin $entries) {
                        [string[]]$entries = $entries + @($downstream)
                        Initialize-AssertValidBranchName $downstream
                    }
                }
            }
        }
    }

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $fw = Register-Framework
    }

    function Add-StandardTests() {
        It 'does nothing when no branches are configured' {
            Initialize-SelectBranches @()
            Initialize-AllUpstreamBranches @{}

            & $PSScriptRoot/git-tool-audit-prune.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        Context 'with branches' {
            BeforeEach {
                Initialize-SelectBranches @(
                    'rc/2022-07-14',
                    'feature/FOO-123',
                    'infra/shared',
                    'main'
                )
            }

            It 'does nothing when existing branches are configured correctly' {
                Initialize-AllUpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123")
                    'feature/FOO-123' = @('infra/shared')
                    'infra/shared' = @('main')
                }
                Initialize-ValidDownstreamBranchNames

                & $PSScriptRoot/git-tool-audit-prune.ps1
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            }

            It 'does not apply with a dry run' {
                Initialize-AllUpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                    'feature/FOO-123' = @('infra/shared')
                    'infra/shared' = @('main')
                    'feature/XYZ-1-services' = @() # intentionally have an extra configured branch here for removal
                }
                Initialize-ValidDownstreamBranchNames
                Initialize-LocalActionSetUpstream @{
                    'feature/XYZ-1-services' = $null
                    'rc/2022-07-14' = @("feature/FOO-123")
                } "Applied changes from 'prune' audit" 'new-commit'
                Initialize-AssertValidBranchName '_upstream'

                & $PSScriptRoot/git-tool-audit-prune.ps1 -dryRun
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
            }

            It 'prunes configuration of extra branches' {
                Initialize-AllUpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                    'feature/FOO-123' = @('infra/shared')
                    'infra/shared' = @('main')
                    'feature/XYZ-1-services' = @() # intentionally have an extra configured branch here for removal
                }
                Initialize-ValidDownstreamBranchNames

                $mock = @(
                    Initialize-LocalActionSetUpstream @{
                        'feature/XYZ-1-services' = $null
                        'rc/2022-07-14' = @("feature/FOO-123")
                    } "Applied changes from 'prune' audit" 'new-commit'
                    Initialize-FinalizeActionSetBranches @{
                        '_upstream' = 'new-commit'
                    }
                )

                & $PSScriptRoot/git-tool-audit-prune.ps1
                $fw.assertDiagnosticOutput | Should -BeNullOrEmpty

                Invoke-VerifyMock $mock -Times 1
            }

            It 'consolidates removed branches' {
                Initialize-AllUpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                    'feature/FOO-123' = @('infra/shared')
                    'infra/shared' = @('main')
                    'feature/XYZ-1-services' = @('infra/shared') # intentionally have an extra configured branch here for removal
                }
                Initialize-ValidDownstreamBranchNames

                $mock = @(
                    Initialize-LocalActionSetUpstream @{
                        'feature/XYZ-1-services' = $null
                        'rc/2022-07-14' = @("feature/FOO-123")
                    } "Applied changes from 'prune' audit" 'new-commit'
                    Initialize-FinalizeActionSetBranches @{
                        '_upstream' = 'new-commit'
                    }
                )

                & $PSScriptRoot/git-tool-audit-prune.ps1
                $fw.assertDiagnosticOutput.Count | Should -Be 1
                $fw.assertDiagnosticOutput | Should -Contain "WARN: Removing 'infra/shared' from upstream branches of 'rc/2022-07-14'; it is redundant via the following: feature/FOO-123"

                Invoke-VerifyMock $mock -Times 1
            }
        }
    }

    Context 'with no remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Initialize-NoCurrentBranch
        }

        Add-StandardTests
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
        }

        Add-StandardTests
    }
}
