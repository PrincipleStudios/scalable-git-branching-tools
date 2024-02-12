BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    # Mock -CommandName Write-Host {}
}

Describe 'git-show-upstream' {
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
            Initialize-UpstreamBranches @{
                'feature/FOO-123' = $("main", "infra/add-services")
                'main' = $()
                'infra/add-services' = $('infra/build-infrastructure')
                'infra/build-infrastructure' = $()
            }
        }

        It 'shows the results of an upstream branch' {
            $result = & ./git-show-upstream.ps1 -noFetch -includeRemote -target 'feature/FOO-123'

            $result | Should -Be @('origin/main', 'origin/infra/add-services')
        }

        Describe 'when using the current branch' {
            # Scenario, as above, with:
            # - current branch is feature/FOO-123
            BeforeEach {
                Initialize-CurrentBranch 'feature/FOO-123'
            }

            It 'shows the results of the current branch if none is specified and including remote in the response' {
                $result = & ./git-show-upstream.ps1 -noFetch -includeRemote
                $result | Should -Be @('origin/main', 'origin/infra/add-services')
            }

            It 'allows specifying the branch with arguments and including remote in the response' {
                $result = & ./git-show-upstream.ps1 -noFetch -includeRemote -target infra/add-services
                $result | Should -Be @('origin/infra/build-infrastructure')
            }

            It 'shows recursive the results of the current branch if none is specified and including remote in the response' {
                $result = & ./git-show-upstream.ps1 -noFetch -includeRemote -recurse
                $result | Should -Be @('origin/main', 'origin/infra/add-services', 'origin/infra/build-infrastructure')
            }
            
            It 'shows the results of the current branch if none is specified' {
                $result = & ./git-show-upstream.ps1 -noFetch
                $result | Should -Be @('main', 'infra/add-services')
            }

            It 'allows specifying the branch with arguments' {
                $result = & ./git-show-upstream.ps1 -noFetch -target infra/add-services
                $result | Should -Be @('infra/build-infrastructure')
            }

            It 'shows recursive the results of the current branch if none is specified' {
                $result = & ./git-show-upstream.ps1 -noFetch -recurse
                $result | Should -Be @('main', 'infra/add-services', 'infra/build-infrastructure')
            }
        }
    }
    
    Describe 'without a remote' {
        # Scenario:
        # - remote configured
        # - upstreams include:
        #     feature/FOO-123 = main & infra/add-services
        #     main = none
        #     infra/add-services = infra/build-infrastructure
        #     infra/build-infrastructure = none
        # - no current branch
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
            Initialize-UpstreamBranches @{
                'feature/FOO-123' = $("main", "infra/add-services")
                'main' = $()
                'infra/add-services' = $('infra/build-infrastructure')
                'infra/build-infrastructure' = $()
            }
        }

        It 'shows the results of an upstream branch' {
            $result = & ./git-show-upstream.ps1 -noFetch -includeRemote -target 'feature/FOO-123'

            $result | Should -Be @('main', 'infra/add-services')
        }

        Describe 'when using the current branch' {
            # Scenario, as above, with:
            # - current branch is feature/FOO-123
            BeforeEach {
                Initialize-CurrentBranch 'feature/FOO-123'
            }

            It 'shows the results of the current branch if none is specified and including remote in the response' {
                $result = & ./git-show-upstream.ps1 -noFetch -includeRemote
                $result | Should -Be @('main', 'infra/add-services')
            }

            It 'allows specifying the branch with arguments and including remote in the response' {
                $result = & ./git-show-upstream.ps1 -noFetch -includeRemote -target infra/add-services
                $result | Should -Be @('infra/build-infrastructure')
            }

            It 'shows recursive the results of the current branch if none is specified and including remote in the response' {
                $result = & ./git-show-upstream.ps1 -noFetch -includeRemote -recurse
                $result | Should -Be @('main', 'infra/add-services', 'infra/build-infrastructure')
            }
            
            It 'shows the results of the current branch if none is specified' {
                $result = & ./git-show-upstream.ps1 -noFetch
                $result | Should -Be @('main', 'infra/add-services')
            }

            It 'allows specifying the branch with arguments' {
                $result = & ./git-show-upstream.ps1 -noFetch -target infra/add-services
                $result | Should -Be @('infra/build-infrastructure')
            }

            It 'shows recursive the results of the current branch if none is specified' {
                $result = & ./git-show-upstream.ps1 -noFetch -recurse
                $result | Should -Be @('main', 'infra/add-services', 'infra/build-infrastructure')
            }
        }
    }
}
