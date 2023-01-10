BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

	. $PSScriptRoot/config/git/Get-Configuration.ps1
	Mock -CommandName Get-ConfiguredAtomicPushEnabled { return $true }

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
    Mock -CommandName Set-UpstreamBranches { throw "Unexpected parameters for Set-UpstreamBranches: $branchName $upstreamBranches $commitMessage" }

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Invoke-WriteTree.ps1
    Mock -CommandName Invoke-WriteTree { throw "Unexpected parameters for Invoke-WriteTree: $treeEntries" }

    . $PSScriptRoot/config/git/Invoke-PreserveBranch.ps1
    Mock -CommandName Invoke-PreserveBranch {
        & $scriptBlock
        & $cleanup
    }

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
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = $nil } }
        
        . $PSScriptRoot/config/git/Get-GitFileNames.ps1
        Mock -CommandName Get-GitFileNames -ParameterFilter { 
            $branchName -eq '_upstream' -AND -not $remote
        } { return $noRemoteBranches | ForEach-Object { $_.branch } }
        
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:feature/FOO-123'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:feature/XYZ-1-services'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:feature/FOO-124-comment'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:feature/FOO-124_FOO-125'} {
            "feature/FOO-124-comment"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:feature/FOO-76'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:integrate/FOO-125_XYZ-1'} {
            "feature/FOO-124_FOO-125"
            "feature/XYZ-1-services"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:main'} {}
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
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = $nil; atomicPushEnabled = $true } }
        
        . $PSScriptRoot/config/git/Get-GitFileNames.ps1
        Mock -CommandName Get-GitFileNames -ParameterFilter { 
            $branchName -eq '_upstream' -AND $remote -eq 'origin'
        } { return $defaultBranches | ForEach-Object { $_.branch } }
        
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:feature/FOO-123'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:feature/XYZ-1-services'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:feature/FOO-124-comment'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:feature/FOO-124_FOO-125'} {
            "feature/FOO-124-comment"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:feature/FOO-76'} {
            "main"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:integrate/FOO-125_XYZ-1'} {
            "feature/FOO-124_FOO-125"
            "feature/XYZ-1-services"
        }
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:main'} {}
    }

    function Mock-UpdateGit() {
        . $PSScriptRoot/config/git/Update-Git.ps1
        Mock -CommandName Update-Git { }
    }
}


Describe 'git-release' {
    It 'handles standard functionality' {
        Mock-RemoteUpstream
        Mock-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }
        
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
        Mock-UpdateGit
        
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }
        
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

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }
        
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
        Mock-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }
        
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
        Mock-UpdateGit

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "integrate/FOO-125_XYZ-1"
        }
        
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
    
}
