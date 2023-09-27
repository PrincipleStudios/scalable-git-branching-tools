Describe 'Invoke-SimplifyAudit' {
    BeforeAll {
        . "$PSScriptRoot/../../utils/testing.ps1"
        Import-Module -Scope Local "$PSScriptRoot/audit-simplify.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Set-MultipleUpstreamBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Select-Branches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Get-GitFileNames.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../git/Update-UpstreamBranch.mocks.psm1"

        Lock-SetMultipleUpstreamBranches
        # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
        Mock -CommandName Write-Host -ModuleName 'audit-simplify' {}
    }

    function CreateTests() {

        It 'does nothing when no branches are configured' {
            Initialize-GitFileNames "$($remotePrefix)_upstream" @()
            Initialize-UpstreamBranches @{ }

            Invoke-SimplifyAudit -apply
        }

        Context "with configured branches" {
            BeforeAll {
                Initialize-GitFileNames "$($remotePrefix)_upstream" @(
                    'rc/2022-07-14',
                    'feature/FOO-123',
                    'feature/XYZ-1-services',
                    'infra/shared'
                )
            }
            It 'does nothing when no branches can be simplified' {
                Initialize-UpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                    'feature/FOO-123' = @('infra/shared')
                    'feature/XYZ-1-services' = @('infra/shared')
                    'infra/shared' = @('main')
                }

                Invoke-SimplifyAudit -apply
            }

            It 'does nothing if "apply" is not specified' {
                Initialize-UpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                    'feature/FOO-123' = @('infra/shared', 'main')
                    'feature/XYZ-1-services' = @('infra/shared')
                    'infra/shared' = @('main')
                }

                Invoke-SimplifyAudit
            }

            It 'adjusts branches to be simplified one step' {
                Initialize-UpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                    'feature/FOO-123' = @('infra/shared', 'main')
                    'feature/XYZ-1-services' = @('infra/shared')
                    'infra/shared' = @('main')
                }

                $mock = @(
                    Initialize-SetMultipleUpstreamBranches @{
                        'feature/FOO-123' = @('infra/shared')
                    } "Applied changes from 'simplify' audit" -commitish 'new-upstream-commit'
                    Initialize-UpdateUpstreamBranch 'new-upstream-commit'
                )

                Invoke-SimplifyAudit -apply

                Invoke-VerifyMock $mock -Times 1
            }

            It 'adjusts branches to be simplified multiple steps' {
                Initialize-UpstreamBranches @{
                    'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services", 'main')
                    'feature/FOO-123' = @('infra/shared')
                    'feature/XYZ-1-services' = @('infra/shared')
                    'infra/shared' = @('main')
                }

                $mock = @(
                    Initialize-SetMultipleUpstreamBranches @{
                        'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")
                    } "Applied changes from 'simplify' audit" -commitish 'new-upstream-commit'
                    Initialize-UpdateUpstreamBranch 'new-upstream-commit'
                )

                Invoke-SimplifyAudit -apply

                Invoke-VerifyMock $mock -Times 1
            }
        }
    }

    Context 'with no remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Initialize-AnyUpstreamBranches
            Initialize-SelectBranches @(
                'rc/2022-07-14',
                'feature/FOO-123',
                # intentionally not including 'feature/XYZ-1-services', though it is mentioned elsewhere,
                # to represent a deleted branch
                'infra/shared',
                'main'
            )
            $remotePrefix = ""
        }

        CreateTests
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-AnyUpstreamBranches
            Initialize-SelectBranches @(
                'rc/2022-07-14',
                'feature/FOO-123',
                # intentionally not including 'feature/XYZ-1-services', though it is mentioned elsewhere,
                # to represent a deleted branch
                'infra/shared',
                'main'
            )
            $remotePrefix = "origin/"
        }

        CreateTests
    }
}
