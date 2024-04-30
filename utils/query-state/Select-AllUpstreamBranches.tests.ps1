BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
}

Describe 'Select-AllUpstreamBranches' {
    BeforeEach {
        Register-Framework
    }

    Describe 'simple structure' {
        BeforeEach {
            Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $mocks = Initialize-AllUpstreamBranches @{
                'my-branch' = @("feature/FOO-123", "feature/XYZ-1-services")
            }
        }

        It 'finds upstream branches from git' {
            (Select-AllUpstreamBranches)['my-branch'] | Should -Be @( 'feature/FOO-123', 'feature/XYZ-1-services' )
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'provides $null for missing branches' {
            (Select-AllUpstreamBranches)['not/a/branch'] | Should -Be $null
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'only runs once, even if called multiple times' {
            Select-AllUpstreamBranches
            Select-AllUpstreamBranches
            Invoke-VerifyMock $mocks -Times 1
            { 
                Invoke-ProcessLogs 'testing' { Invoke-VerifyMock $mocks -Times 2 }
            } | Should -Throw
        }

        It 'runs twice if specified' {
            Select-AllUpstreamBranches
            Select-AllUpstreamBranches -refresh
            Invoke-VerifyMock $mocks -Times 2
        }
    }

    Describe 'complex structures' {
        BeforeEach {
            Initialize-ToolConfiguration
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
            $mocks = Initialize-AllUpstreamBranches @{
                'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-123' = @("line/1.0")
                'feature/XYZ-1-services' = @("infra/some-service")
                'infra/some-service' = @("line/1.0")
            }
        }

        It 'handles deep folders' {
            (Select-AllUpstreamBranches)['feature/FOO-123'] | Should -Be @("line/1.0")
            (Select-AllUpstreamBranches)['feature/XYZ-1-services'] | Should -Be @("infra/some-service")
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Describe 'at an alternate commit' {
        BeforeEach {
            Initialize-ToolConfiguration
        }

        It 'handles deep folders' {
            $mocks = Initialize-AllUpstreamBranches @{
                'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/XYZ-1-services' = @("infra/some-service")
                'infra/some-service' = @("line/1.0")
            }
            $overrideUpstreams = @{
                'feature/FOO-123' = @("line/1.0")
                'infra/some-service' = @('main')
            };

            (Select-AllUpstreamBranches -overrideUpstreams $overrideUpstreams)['feature/FOO-123'] | Should -Be @("line/1.0")
            (Select-AllUpstreamBranches -overrideUpstreams $overrideUpstreams)['feature/XYZ-1-services'] | Should -Be @("infra/some-service")
            (Select-AllUpstreamBranches -overrideUpstreams $overrideUpstreams)['infra/some-service'] | Should -Be @("main")
            Invoke-VerifyMock $mocks -Times 1
        }
    }
}
