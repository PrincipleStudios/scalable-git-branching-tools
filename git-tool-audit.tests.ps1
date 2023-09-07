Describe "git-tool-audit" {
    BeforeAll {
        . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
        Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"

        # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
        Mock -CommandName Write-Host { }

        Import-Module -Scope Local "$PSScriptRoot/config/audit/audit-prune.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/audit/audit-simplify.psm1"
    }
    BeforeEach {
        Register-Framework
    }

    function CreateStandardAuditTests() {
        It "passes apply when specified" {
            Mock -CommandName $commandName -MockWith { }

            & ./git-tool-audit.ps1 -apply @splat

            Should -Invoke -CommandName $commandName -ParameterFilter { $apply -eq $true } -Times 1
        }

        It "does not pass apply when not specified" {
            Mock -CommandName $commandName -MockWith { }

            & ./git-tool-audit.ps1 @splat

            Should -Invoke -CommandName $commandName -ParameterFilter { $apply -eq $false } -Times 1
        }
    }

    function CreateAllStandardAuditTests() {
        Context "prune" {
            BeforeAll {
                $splat = @{ 'prune' = $true }
                $commandName = 'Invoke-PruneAudit'
            }
            CreateStandardAuditTests
        }

        Context "simplify" {
            BeforeAll {
                $splat = @{ 'simplify' = $true }
                $commandName = 'Invoke-SimplifyAudit'
            }
            CreateStandardAuditTests
        }

        Context "all" {
            BeforeAll {
                $splat = @{}
                Mock -CommandName 'Invoke-PruneAudit' -MockWith { }
                Mock -CommandName 'Invoke-SimplifyAudit' -MockWith { }
            }

            It "passes apply to all audits" {
                & ./git-tool-audit.ps1 -apply

                Should -Invoke -CommandName 'Invoke-PruneAudit' -ParameterFilter { $apply -eq $true } -Times 1
                Should -Invoke -CommandName 'Invoke-SimplifyAudit' -ParameterFilter { $apply -eq $true } -Times 1
            }

            It "does not pass apply to any audits" {
                & ./git-tool-audit.ps1

                Should -Invoke -CommandName 'Invoke-PruneAudit' -ParameterFilter { $apply -eq $false } -Times 1
                Should -Invoke -CommandName 'Invoke-SimplifyAudit' -ParameterFilter { $apply -eq $false } -Times 1
            }
        }
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote -prune
        }
        CreateAllStandardAuditTests
    }

    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Initialize-UpdateGitRemote -prune
        }
        CreateAllStandardAuditTests
    }

}