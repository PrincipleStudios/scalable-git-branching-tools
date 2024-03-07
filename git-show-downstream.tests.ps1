BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    # Mock -CommandName Write-Host {}
}

Describe 'git-show-downstream' {
    Describe 'with a remote' {
        # Scenario:
        # - remote configured
        # - upstreams include:
        #     feature/FOO-123 = main & infra/add-services
        #     main = none
        #     infra/add-services = infra/build-infrastructure
        #     infra/build-infrastructure = none
        # - no current branch
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-AllUpstreamBranches @{
                'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
                'feature/FOO-124' = @("feature/FOO-123")
                'feature/FOO-123' = @("main")
                'feature/XYZ-1-services' = @("main")
                'rc/1.1.0' = @("integrate/FOO-123_XYZ-1")
    
                'bad-recursive-branch-1' = @('bad-recursive-branch-2')
                'bad-recursive-branch-2' = @('bad-recursive-branch-1')
            }
        }

        It 'shows the results of an downstream branch' {
            $result = & ./git-show-downstream.ps1 -noFetch -target 'feature/FOO-123'

            Should -ActualValue $result.Length -Be 2
            Should -ActualValue $result -BeLike 'feature/FOO-124'
            Should -ActualValue $result -BeLike 'integrate/FOO-123_XYZ-1'
        }

        Describe 'when using the current branch' {
            # Scenario, as above, with:
            # - current branch is feature/FOO-123
            BeforeEach {
                Initialize-CurrentBranch 'feature/FOO-123'
            }

            It 'shows the results of the current branch if none is specified' {
                $result = & ./git-show-downstream.ps1 -noFetch

                Should -ActualValue $result.Length -Be 2
                Should -ActualValue $result -BeLike 'feature/FOO-124'
                Should -ActualValue $result -BeLike 'integrate/FOO-123_XYZ-1'
            }

            It 'allows specifying the branch with arguments and including remote in the response' {
                $result = & ./git-show-downstream.ps1 -noFetch -target 'main'

                Should -ActualValue $result.Length -Be 2
                Should -ActualValue $result -BeLike 'feature/FOO-123'
                Should -ActualValue $result -BeLike 'feature/XYZ-1-services'
            }

            It 'shows recursive the results of the current branch if none is specified' {
                $result = & ./git-show-downstream.ps1 -noFetch -recurse

                Should -ActualValue $result.Length -Be 3
                Should -ActualValue $result -BeLike 'feature/FOO-124'
                Should -ActualValue $result -BeLike 'integrate/FOO-123_XYZ-1'
                Should -ActualValue $result -BeLike 'rc/1.1.0'
            }

            It 'shows recursive the results of the a specified branch' {
                $result = & ./git-show-downstream.ps1 -noFetch -recurse -target 'main'

                Should -ActualValue $result.Length -Be 5
                Should -ActualValue $result -BeLike 'feature/FOO-123'
                Should -ActualValue $result -BeLike 'feature/XYZ-1-services'
                Should -ActualValue $result -BeLike 'feature/FOO-124'
                Should -ActualValue $result -BeLike 'integrate/FOO-123_XYZ-1'
                Should -ActualValue $result -BeLike 'rc/1.1.0'
            }
        }
    }
}
