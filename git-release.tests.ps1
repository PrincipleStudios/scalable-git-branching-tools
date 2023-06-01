BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-GitFileNames.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-WriteTree.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    Lock-InvokeWriteTree
    Lock-SetMultipleUpstreamBranches
}


Describe 'git-release' {
    Context 'without a remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote -defaultServiceLine $nil

            $noRemoteBranches = @(
                @{ remote = $nil; branch='feature/FOO-123' }
                @{ remote = $nil; branch='feature/FOO-124-comment' }
                @{ remote = $nil; branch='feature/FOO-124_FOO-125' }
                @{ remote = $nil; branch='feature/FOO-76' }
                @{ remote = $nil; branch='feature/XYZ-1-services' }
                @{ remote = $nil; branch='main' }
                @{ remote = $nil; branch='rc/2022-07-14' }
                @{ remote = $nil; branch='integrate/FOO-125_XYZ-1' }
            )

            Initialize-GitFileNames '_upstream' $($noRemoteBranches | ForEach-Object { $_.branch })
            Initialize-UpstreamBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = @()
            }
        }
        It 'handles standard functionality' {

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list main ^rc/2022-07-14 --count'} {
                "0"
            }
            Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")}
            Initialize-SetMultipleUpstreamBranches @{

                'feature/FOO-123' = $nil;
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125", "main");
                'rc/2022-07-14' = $nil;
                'feature/XYZ-1-services' = $nil;
            } 'Release rc/2022-07-14 to main' 'new-commit'

            $updateBranchFilters = @(
                {($args -join ' ') -eq 'branch -f _upstream new-commit'}
                {($args -join ' ') -eq 'branch -f rc/2022-07-14 main'}
                {($args -join ' ') -eq 'branch -D feature/FOO-123'}
                {($args -join ' ') -eq 'branch -D feature/XYZ-1-services'}
                {($args -join ' ') -eq 'branch -D rc/2022-07-14'}
            )
            $updateBranchFilters | ForEach-Object { Mock git -ParameterFilter $_ {} -Verifiable }

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main

            $updateBranchFilters | ForEach-Object { Should -Invoke -CommandName git -Times 1 -ParameterFilter $_ }
        }
    }

    Context 'with a remote' {
        BeforeAll {
            $defaultBranches = @(
                @{ remote = 'origin'; branch='feature/FOO-123' }
                @{ remote = 'origin'; branch='feature/FOO-124-comment' }
                @{ remote = 'origin'; branch='feature/FOO-124_FOO-125' }
                @{ remote = 'origin'; branch='feature/FOO-76' }
                @{ remote = 'origin'; branch='feature/XYZ-1-services' }
                @{ remote = 'origin'; branch='main' }
                @{ remote = 'origin'; branch='rc/2022-07-14' }
                @{ remote = 'origin'; branch='integrate/FOO-125_XYZ-1' }
            )

            Initialize-ToolConfiguration -defaultServiceLine $nil

            Initialize-GitFileNames 'origin/_upstream' $($defaultBranches | ForEach-Object { $_.branch })
            Initialize-UpstreamBranches @{
                'feature/FOO-123' = @('main')
                'feature/XYZ-1-services' = @('main')
                'feature/FOO-124-comment' = @('main')
                'feature/FOO-124_FOO-125' = @("feature/FOO-124-comment")
                'feature/FOO-76' = @('main')
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125","feature/XYZ-1-services")
                'main' = {}
            }
        }

        It 'handles standard functionality' {
            Initialize-UpdateGit

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
                "0"
            }
            Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

            Initialize-SetMultipleUpstreamBranches @{
                'feature/FOO-123' = $nil
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125", "main")
                'rc/2022-07-14' = $nil
                'feature/XYZ-1-services' = $nil
            } -commitMessage 'Release rc/2022-07-14 to main' -resultCommitish 'new-commit'

            $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
            Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main

            Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
        }

        It 'can skip the initial fetch' {
            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
                "0"
            }

            Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

            Initialize-SetMultipleUpstreamBranches @{
                'feature/FOO-123' = $nil
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125", "main")
                'rc/2022-07-14' = $nil
                'feature/XYZ-1-services' = $nil
            } -commitMessage 'Release rc/2022-07-14 to main' -resultCommitish 'new-commit'

            $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
            Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -noFetch

            Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
        }

        It 'can issue a dry run' {
            Initialize-UpdateGit

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
                "0"
            }

            Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

            Initialize-SetMultipleUpstreamBranches @{
                'feature/FOO-123' = $nil
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125", "main")
                'rc/2022-07-14' = $nil
                'feature/XYZ-1-services' = $nil
            } -commitMessage 'Release rc/2022-07-14 to main' -resultCommitish 'new-commit'

            $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
            Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -dryrun
        }

        It 'handles integration branches recursively' {
            Initialize-UpdateGit

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
                "0"
            }

            Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1") }

            Initialize-SetMultipleUpstreamBranches @{
                'feature/FOO-123' = $nil
                'integrate/FOO-125_XYZ-1' = $nil
                'rc/2022-07-14' = $nil
                'feature/XYZ-1-services' = $nil
                'feature/FOO-124_FOO-125' = $nil
                'feature/FOO-124-comment' = $nil
            } -commitMessage 'Release rc/2022-07-14 to main' -resultCommitish 'new-commit'

            $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :integrate/FOO-125_XYZ-1 :feature/FOO-124_FOO-125 :feature/XYZ-1-services :feature/FOO-124-comment :rc/2022-07-14 new-commit:refs/heads/_upstream'}
            Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main

            Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
        }

        It 'handles a single upstream branch' {
            Initialize-UpdateGit

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/feature/FOO-123 --count'} {
                "0"
            }
            Initialize-UpstreamBranches @{
                'feature/FOO-123' = @('main')
                'rc/2022-07-14' = @("integrate/FOO-125_XYZ-1")
            }

            Initialize-SetMultipleUpstreamBranches @{
                'feature/FOO-123' = $nil
            } -commitMessage 'Release feature/FOO-123 to main' -resultCommitish 'new-commit'
            $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/feature/FOO-123:main :feature/FOO-123 new-commit:refs/heads/_upstream'}
            Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

            & $PSScriptRoot/git-release.ps1 feature/FOO-123 main

            Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
        }

        It 'aborts if not a fast-forward' {
            Initialize-UpdateGit

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
                "1"
            }

            { & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main } | Should -Throw
        }

        It 'can clean up if already released' {
            Initialize-UpdateGit

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/rc/2022-07-14 ^origin/main --count'} {
                "0"
            }

            Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

            Initialize-SetMultipleUpstreamBranches @{
                'feature/FOO-123' = $nil
                'integrate/FOO-125_XYZ-1' = @("feature/FOO-124_FOO-125", "main")
                'rc/2022-07-14' = $nil
                'feature/XYZ-1-services' = $nil
            } -commitMessage 'Release rc/2022-07-14 to main' -resultCommitish 'new-commit'

            $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
            Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

            & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -cleanupOnly

            Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
        }

        It 'aborts clean up if not already released' {
            Initialize-UpdateGit

            Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/rc/2022-07-14 ^origin/main --count'} {
                "1"
            }

            { & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -cleanupOnly } | Should -Throw
        }
    }
}
