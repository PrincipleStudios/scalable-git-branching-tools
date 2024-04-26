Describe 'Invoke-PruneAudit' {
    BeforeAll {
        . "$PSScriptRoot/utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
        
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

        
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $initialCommits = @{
            'rc/2022-07-14' = 'rc/2022-07-14-commitish'
            'main' = 'main-commitish'
            'feature/FOO-123' = 'feature/FOO-123-commitish'
            'feature/XYZ-1-services' = 'feature/XYZ-1-services-commitish'
            'infra/shared' = 'infra/shared-commitish'
        }
    }

    function Add-StandardTests() {
        It 'does nothing when no branches are configured' {
            Initialize-SelectBranches @()
            Initialize-AllUpstreamBranches @{}

            & $PSScriptRoot/git-tool-audit-prune.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'does nothing when existing branches are configured correctly' -Pending {
            Initialize-AllUpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123")
                'feature/FOO-123' = @('infra/shared')
                'infra/shared' = @('main')
            }
            Initialize-ValidDownstreamBranchNames

            & $PSScriptRoot/git-tool-audit-prune.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'does not apply with a dry run' -Pending {
            Initialize-AllUpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                'feature/FOO-123' = @('infra/shared')
                'infra/shared' = @('main')
                'feature/XYZ-1-services' = @('infra/shared') # intentionally have an extra configured branch here for removal
            }
            Initialize-ValidDownstreamBranchNames

            & $PSScriptRoot/git-tool-audit-prune.ps1 -dryRun
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty
        }

        It 'prunes configuration of extra branches' -Pending {
            Initialize-AllUpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                'feature/FOO-123' = @('infra/shared')
                'feature/XYZ-1-services' = @('infra/shared') # intentionally have an extra configured branch here for removal
                'infra/shared' = @('main')
            }
            Initialize-ValidDownstreamBranchNames

            $mock = @(
                # TODO - save
            )

            & $PSScriptRoot/git-tool-audit-prune.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty

            Invoke-VerifyMock $mock -Times 1
        }

        It 'consolidates removed branches' -Pending {
            # TODO  -setup

            $mock = @(
                # TODO: save
            )

            & $PSScriptRoot/git-tool-audit-prune.ps1
            $fw.assertDiagnosticOutput | Should -BeNullOrEmpty

            Invoke-VerifyMock $mock -Times 1
        }
    }

    Context 'with no remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Initialize-SelectBranches @(
                'rc/2022-07-14',
                'feature/FOO-123',
                'infra/shared',
                'main'
            )
        }

        Add-StandardTests
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
            Initialize-SelectBranches @(
                'rc/2022-07-14',
                'feature/FOO-123',
                'infra/shared',
                'main'
            )
        }

        Add-StandardTests
    }
}
