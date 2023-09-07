Describe 'Invoke-PruneAudit' {
    BeforeAll {
        . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
        Import-Module -Scope Local "$PSScriptRoot/audit-prune.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Set-MultipleUpstreamBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Select-UpstreamBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Select-Branches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Get-GitFileNames.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Update-UpstreamBranch.mocks.psm1"
        . $PSScriptRoot/../TestUtils.ps1

        Lock-SetMultipleUpstreamBranches
        # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
        Mock -CommandName Write-Host -ModuleName 'audit-prune' {}
    }

    function CreateTests() {
        It 'does nothing when no branches are configured' {
            Initialize-UpstreamBranches @{ }
            Initialize-GitFileNames "$($remotePrefix)_upstream" @()

            Invoke-PruneAudit -apply
        }

        It 'does nothing when existing branches are configured' {
            Initialize-UpstreamBranches @{ }
            Initialize-GitFileNames "$($remotePrefix)_upstream" @(
                'rc/2022-07-14',
                'feature/FOO-123',
                'infra/shared',
                'main'
            )

            Invoke-PruneAudit -apply
        }

        It 'does not apply if the switch is not passed' {
            Initialize-UpstreamBranches @{ }
            Initialize-GitFileNames "$($remotePrefix)_upstream" @(
                'rc/2022-07-14',
                'feature/FOO-123',
                'feature/XYZ-1-services', # intentionally have an extra configured branch here
                'infra/shared',
                'main'
            )

            Invoke-PruneAudit
        }

        It 'prunes configuration of extra branches' {
            Initialize-UpstreamBranches @{ }
            Initialize-GitFileNames "$($remotePrefix)_upstream" @(
                'rc/2022-07-14',
                'feature/FOO-123',
                'feature/XYZ-1-services', # intentionally have an extra configured branch here
                'infra/shared',
                'main'
            )

            $mock = @(
                Initialize-SetMultipleUpstreamBranches @{
                    'feature/XYZ-1-services' = $nil
                } "Applied changes from 'prune' audit" -commitish 'new-upstream-commit'
                Initialize-UpdateUpstreamBranch 'new-upstream-commit'
            )

            Invoke-PruneAudit -apply

            Invoke-VerifyMock $mock -Times 1
        }

        It 'consolidates removed branches' {
            Initialize-UpstreamBranches @{
                'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                'feature/FOO-123' = @('infra/shared')
                'feature/XYZ-1-services' = @('infra/shared')
                'infra/shared' = @('main')
            }
            Initialize-GitFileNames "$($remotePrefix)_upstream" @(
                'rc/2022-07-14',
                'feature/FOO-123',
                'feature/XYZ-1-services', # intentionally have an extra configured branch here
                'infra/shared',
                'main'
            )

            $mock = @(
                Initialize-SetMultipleUpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123")
                    'feature/XYZ-1-services' = $nil
                } "Applied changes from 'prune' audit" -commitish 'new-upstream-commit'
                Initialize-UpdateUpstreamBranch 'new-upstream-commit'
            )

            Invoke-PruneAudit -apply

            Invoke-VerifyMock $mock -Times 1
        }

        # TODO - would this be a more correct behavior? I believe so, but it depends.
        # It 'consolidates removed branches to remaining upstream' {
        #     Initialize-UpstreamBranches @{
        #         'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
        #         'feature/FOO-123' = @()
        #         'feature/XYZ-1-services' = @('infra/shared')
        #         'infra/shared' = @('main')
        #     }
        #     Initialize-GitFileNames "$($remotePrefix)_upstream" @(
        #         'rc/2022-07-14',
        #         'feature/FOO-123',
        #         'feature/XYZ-1-services', # intentionally have an extra configured branch here
        #         'infra/shared',
        #         'main'
        #     )

        #     $mock = @(
        #         Initialize-SetMultipleUpstreamBranches @{
        #             'rc/2022-07-14' = @("feature/FOO-123", 'infra/shared')
        #             'feature/XYZ-1-services' = $nil
        #         } "Applied changes from 'prune' audit" -commitish 'new-upstream-commit'
        #         Initialize-UpdateUpstreamBranch 'new-upstream-commit'
        #     )

        #     Invoke-PruneAudit -apply

        #     Invoke-VerifyMock $mock -Times 1
        # }
    }

    Context 'with no remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Initialize-AnyUpstreamBranches
            Initialize-SelectBranches @(
                'rc/2022-07-14',
                'feature/FOO-123',
                'infra/shared',
                'main'
            )
            $remotePrefix = ''
        }

        CreateTests
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-AnyUpstreamBranches
            Initialize-SelectBranches @(
                'origin/rc/2022-07-14',
                'origin/feature/FOO-123',
                'origin/infra/shared',
                'origin/main'
            )
            $remotePrefix = 'origin/'
        }

        CreateTests
    }
}
