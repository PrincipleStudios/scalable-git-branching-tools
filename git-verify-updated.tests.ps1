BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/input.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/actions.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}
}


Describe 'git-verify-updated' {
    BeforeEach {
        Register-Framework
    }

    function Add-StandardTests {
        It 'fails if no current branch and none provided' {
            Initialize-NoCurrentBranch

            { & $PSScriptRoot/git-verify-updated.ps1 } | Should -Throw
        }
    
        It 'uses the default branch when none specified' {
            $mocks = @(
                Initialize-CurrentBranch 'feature/PS-2'
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-UpstreamBranches @{ 'feature/PS-2' = @('feature/PS-1','infra/build-improvements') }
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('feature/PS-1','infra/build-improvements') `
                    -noChangeBranches @('feature/PS-1','infra/build-improvements') `
                    -resultCommitish 'result-commitish' `
                    -source 'feature/PS-2'
            )

            & $PSScriptRoot/git-verify-updated.ps1
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'uses the branch specified' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-UpstreamBranches @{ 'feature/PS-2' = @('feature/PS-1','infra/build-improvements') }
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('feature/PS-1','infra/build-improvements') `
                    -noChangeBranches @('feature/PS-1','infra/build-improvements') `
                    -resultCommitish 'result-commitish' `
                    -source 'feature/PS-2'
            )

            & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'fails if there are no upstreams on the initial branch' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-UpstreamBranches @{ 'feature/PS-2' = @() }
            )

            { & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2 }
                | Should -Throw 'ERR:  feature/PS-2 has no upstream branches to verify.'
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'throws when one branch is out of date' {
            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-UpstreamBranches @{ 'feature/PS-2' = @('feature/PS-1','infra/build-improvements') }
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('feature/PS-1','infra/build-improvements') `
                    -successfulBranches @('feature/PS-1') `
                    -noChangeBranches @('infra/build-improvements') `
                    -resultCommitish 'result-commitish' `
                    -source 'feature/PS-2'
            )

            { & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2 }
                | Should -Throw 'ERR:  feature/PS-2 did not have the latest from feature/PS-1.'
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'uses the branch specified, recursively' {
            $remote = $(Get-Configuration).remote
            $remotePrefix = $remote ? "$remote/" : ""
            $initialCommits = @{
                "$($remotePrefix)main" = "$($remotePrefix)main-commitish"
                "$($remotePrefix)feature/PS-1" = "$($remotePrefix)feature/PS-1-commitish"
                "$($remotePrefix)infra/ts-update" = "$($remotePrefix)infra/ts-update-commitish"
                "$($remotePrefix)infra/build-improvements" = "$($remotePrefix)infra/build-improvements-commitish"
                "$($remotePrefix)feature/PS-2" = "$($remotePrefix)feature/PS-2-commitish"
            }

            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-UpstreamBranches @{
                    'feature/PS-2' = @('feature/PS-1','infra/build-improvements')
                    'feature/PS-1' = @('infra/ts-update')
                    'infra/build-improvements' = @('infra/ts-update')
                    'infra/ts-update' = @('main')
                }
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-1'
                Initialize-LocalActionAssertPushedSuccess 'infra/build-improvements'
                Initialize-LocalActionAssertPushedSuccess 'infra/ts-update'
                Initialize-LocalActionAssertPushedSuccess 'main'

                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('main') `
                    -noChangeBranches @('main') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/ts-update"] `
                    -source 'infra/ts-update' `
                    -initialCommits $initialCommits
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('infra/ts-update') `
                    -noChangeBranches @('infra/ts-update') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/build-improvements"] `
                    -source 'infra/build-improvements' `
                    -initialCommits $initialCommits
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('infra/ts-update') `
                    -noChangeBranches @('infra/ts-update') `
                    -resultCommitish $initialCommits["$($remotePrefix)feature/PS-1"] `
                    -source 'feature/PS-1' `
                    -initialCommits $initialCommits
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('feature/PS-1','infra/build-improvements') `
                    -noChangeBranches @('feature/PS-1','infra/build-improvements') `
                    -resultCommitish $initialCommits["$($remotePrefix)feature/PS-2"] `
                    -source 'feature/PS-2' `
                    -initialCommits $initialCommits
            )

            & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2 -recurse
            Invoke-VerifyMock $mocks -Times 1
        }

        It 'uses the branch specified, and fails on the first out-of-date branch' {
            $remote = $(Get-Configuration).remote
            $remotePrefix = $remote ? "$remote/" : ""
            $initialCommits = @{
                "$($remotePrefix)main" = "$($remotePrefix)main-commitish"
                "$($remotePrefix)feature/PS-1" = "$($remotePrefix)feature/PS-1-commitish"
                "$($remotePrefix)infra/ts-update" = "$($remotePrefix)infra/ts-update-commitish"
                "$($remotePrefix)infra/build-improvements" = "$($remotePrefix)infra/build-improvements-commitish"
                "$($remotePrefix)feature/PS-2" = "$($remotePrefix)feature/PS-2-commitish"
            }

            $mocks = @(
                Initialize-AssertValidBranchName 'feature/PS-2'
                Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-2'
                Initialize-UpstreamBranches @{
                    'feature/PS-2' = @('feature/PS-1','infra/build-improvements')
                    'feature/PS-1' = @('infra/ts-update')
                    'infra/build-improvements' = @('infra/ts-update')
                    'infra/ts-update' = @('main')
                }
                Initialize-LocalActionAssertPushedSuccess 'feature/PS-1'
                Initialize-LocalActionAssertPushedSuccess 'infra/build-improvements'
                Initialize-LocalActionAssertPushedSuccess 'infra/ts-update'
                Initialize-LocalActionAssertPushedSuccess 'main'

                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('main') `
                    -noChangeBranches @('main') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/ts-update"] `
                    -source 'infra/ts-update' `
                    -initialCommits $initialCommits
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('infra/ts-update') `
                    -noChangeBranches @('infra/ts-update') `
                    -resultCommitish $initialCommits["$($remotePrefix)feature/PS-1"] `
                    -source 'feature/PS-1' `
                    -initialCommits $initialCommits
                Initialize-LocalActionMergeBranches `
                    -upstreamBranches @('infra/ts-update') `
                    -resultCommitish $initialCommits["$($remotePrefix)infra/build-improvements"] `
                    -source 'infra/build-improvements' `
                    -initialCommits $initialCommits
            )

            { & $PSScriptRoot/git-verify-updated.ps1 -target feature/PS-2 -recurse }
                | Should -Throw "ERR:  infra/build-improvements has incoming conflicts from infra/ts-update."
            Invoke-VerifyMock $mocks -Times 1
        }
    }

    Context 'without a remote' {
        BeforeEach {
            Initialize-ToolConfiguration -noRemote
        }

        Add-StandardTests
    }

    Context 'with a remote' {
        BeforeEach {
            Initialize-ToolConfiguration
            Initialize-UpdateGitRemote
        }

        Add-StandardTests
    
        It 'uses the current branch if none specified, but fails if not pushed' {
            Initialize-CurrentBranch 'feature/PS-2'
            Initialize-AssertValidBranchName 'feature/PS-2'
            Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
            Initialize-LocalActionAssertPushedAhead 'feature/PS-2'

            { & $PSScriptRoot/git-verify-updated.ps1 }
                | Should -Throw "ERR:  The local branch for feature/PS-2 has changes that are not pushed to the remote"
        }

        It 'uses the current branch if none specified, but fails if not tracked to the remote' {
            Initialize-CurrentBranch 'feature/PS-2'
            Initialize-AssertValidBranchName 'feature/PS-2'
            Initialize-LocalActionAssertExistence -branches @('feature/PS-2') -shouldExist $true
            Initialize-LocalActionAssertPushedNotTracked 'feature/PS-2'

            { & $PSScriptRoot/git-verify-updated.ps1 }
                | Should -Throw "ERR:  The local branch for feature/PS-2 does not exist on the remote"
        }
    }

}
