BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-GitFileNames.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-WriteTree.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
    Mock -CommandName Set-UpstreamBranches { throw "Unexpected parameters for Set-UpstreamBranches: $branchName $upstreamBranches $commitMessage" }

    Lock-InvokeWriteTree

    . $PSScriptRoot/config/git/Set-GitFiles.ps1
    Mock -CommandName Set-GitFiles {
        throw "Unexpected parameters for Set-GitFiles: $(@{ files = $files; commitMessage = $commitMessage; branchName = $branchName; remote = $remote; dryRun = $dryRun } | ConvertTo-Json)"
    }

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

    function Mock-NoRemoteUpstream() {
        Initialize-ToolConfiguration -noRemote -defaultServiceLine $nil

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

    function Mock-RemoteUpstream() {
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
}


Describe 'git-release' {
    It 'handles standard functionality' {
        Mock-RemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
            "0"
        }
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $commitMessage -eq 'Release rc/2022-07-14 to main' -AND $branchName -eq '_upstream' -AND $remote -eq 'origin' -AND $dryRun `
                -AND $files['feature/FOO-123'] -eq $nil `
                -AND $files['integrate/FOO-125_XYZ-1'] -eq "feature/FOO-124_FOO-125`nmain" `
                -AND $files['rc/2022-07-14'] -eq $nil `
                -AND $files['feature/XYZ-1-services'] -eq $nil
        } {
            'new-commit'
        }

        $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
        Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

        & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main

        Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
    }

    It 'handles no remote' {
        Mock-NoRemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list main ^rc/2022-07-14 --count'} {
            "0"
        }
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services")}

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $commitMessage -eq 'Release rc/2022-07-14 to main' -AND $branchName -eq '_upstream' -AND -not $remote -AND $dryRun `
                -AND $files['feature/FOO-123'] -eq $nil `
                -AND $files['integrate/FOO-125_XYZ-1'] -eq "feature/FOO-124_FOO-125`nmain" `
                -AND $files['rc/2022-07-14'] -eq $nil `
                -AND $files['feature/XYZ-1-services'] -eq $nil
        } {
            'new-commit'
        }

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

    It 'can skip the initial fetch' {
        Mock-RemoteUpstream

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
            "0"
        }

        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $commitMessage -eq 'Release rc/2022-07-14 to main' -AND $branchName -eq '_upstream' -AND $remote -eq 'origin' -AND $dryRun `
                -AND $files['feature/FOO-123'] -eq $nil `
                -AND $files['integrate/FOO-125_XYZ-1'] -eq "feature/FOO-124_FOO-125`nmain" `
                -AND $files['rc/2022-07-14'] -eq $nil `
                -AND $files['feature/XYZ-1-services'] -eq $nil
        } {
            'new-commit'
        }

        $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
        Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

        & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -noFetch

        Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
    }

    It 'can issue a dry run' {
        Mock-RemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
            "0"
        }

        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $commitMessage -eq 'Release rc/2022-07-14 to main' -AND $branchName -eq '_upstream' -AND $remote -eq 'origin' -AND $dryRun `
                -AND $files['feature/FOO-123'] -eq $nil `
                -AND $files['integrate/FOO-125_XYZ-1'] -eq "feature/FOO-124_FOO-125`nmain" `
                -AND $files['rc/2022-07-14'] -eq $nil `
                -AND $files['feature/XYZ-1-services'] -eq $nil
        } {
            'new-commit'
        }

        $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
        Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

        & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -dryrun
    }

    It 'handles integration branches recursively' {
        Mock-RemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
            "0"
        }

        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123", "integrate/FOO-125_XYZ-1") }

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $commitMessage -eq 'Release rc/2022-07-14 to main' -AND $branchName -eq '_upstream' -AND $remote -eq 'origin' -AND $dryRun `
                -AND $files['feature/FOO-123'] -eq $nil `
                -AND $files['integrate/FOO-125_XYZ-1'] -eq $nil `
                -AND $files['rc/2022-07-14'] -eq $nil `
                -AND $files['feature/XYZ-1-services'] -eq $nil `
                -AND $files['feature/FOO-124_FOO-125'] -eq $nil `
                -AND $files['feature/FOO-124-comment'] -eq $nil
        } {
            'new-commit'
        }

        $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/rc/2022-07-14:main :feature/FOO-123 :integrate/FOO-125_XYZ-1 :feature/FOO-124_FOO-125 :feature/XYZ-1-services :feature/FOO-124-comment :rc/2022-07-14 new-commit:refs/heads/_upstream'}
        Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

        & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main

        Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
    }

    It 'handles a single upstream branch' {
        Mock-RemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/feature/FOO-123 --count'} {
            "0"
        }
        Initialize-UpstreamBranches @{
            'feature/FOO-123' = @('main')
            'rc/2022-07-14' = @("integrate/FOO-125_XYZ-1")
        }

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $commitMessage -eq 'Release feature/FOO-123 to main' -AND $branchName -eq '_upstream' -AND $remote -eq 'origin' -AND $dryRun `
                -AND $files['feature/FOO-123'] -eq $nil
        } {
            'new-commit'
        }

        $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin origin/feature/FOO-123:main :feature/FOO-123 new-commit:refs/heads/_upstream'}
        Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

        & $PSScriptRoot/git-release.ps1 feature/FOO-123 main

        Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
    }

    It 'aborts if not a fast-forward' {
        Mock-RemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/main ^origin/rc/2022-07-14 --count'} {
            "1"
        }

        { & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main } | Should -Throw
    }

    It 'can clean up if already released' {
        Mock-RemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/rc/2022-07-14 ^origin/main --count'} {
            "0"
        }

        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $commitMessage -eq 'Release rc/2022-07-14 to main' -AND $branchName -eq '_upstream' -AND $remote -eq 'origin' -AND $dryRun `
                -AND $files['feature/FOO-123'] -eq $nil `
                -AND $files['integrate/FOO-125_XYZ-1'] -eq "feature/FOO-124_FOO-125`nmain" `
                -AND $files['rc/2022-07-14'] -eq $nil `
                -AND $files['feature/XYZ-1-services'] -eq $nil
        } {
            'new-commit'
        }

        $pushParameterFilter = {($args -join ' ') -eq 'push --atomic origin :feature/FOO-123 :feature/XYZ-1-services :rc/2022-07-14 new-commit:refs/heads/_upstream'}
        Mock git -ParameterFilter $pushParameterFilter {} -Verifiable

        & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -cleanupOnly

        Should -Invoke -CommandName git -Times 1 -ParameterFilter $pushParameterFilter
    }

    It 'aborts clean up if not already released' {
        Mock-RemoteUpstream
        Initialize-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'rev-list origin/rc/2022-07-14 ^origin/main --count'} {
            "1"
        }

        { & $PSScriptRoot/git-release.ps1 rc/2022-07-14 main -cleanupOnly } | Should -Throw
    }

}
