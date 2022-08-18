BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    . $PSScriptRoot/config/git/Invoke-PreserveBranch.ps1
    Mock -CommandName Invoke-PreserveBranch {
        & $scriptBlock
        if ($cleanup -ne $nil) { & $cleanup }
    }

    $noRemoteBranches = @(
        @{ remote = $nil; branch='feature/FOO-123'; type = 'feature'; ticket='FOO-123' }
        @{ remote = $nil; branch='feature/FOO-124-comment'; type = 'feature'; ticket='FOO-124'; comment='comment' }
        @{ remote = $nil; branch='feature/FOO-124_FOO-125'; type = 'feature'; ticket='FOO-125'; parents=@('FOO-124') }
        @{ remote = $nil; branch='feature/FOO-76'; type = 'feature'; ticket='FOO-76' }
        @{ remote = $nil; branch='feature/XYZ-1-services'; type = 'feature'; ticket='XYZ-1'; comment='services' }
        @{ remote = $nil; branch='main'; type = 'service-line' }
        @{ remote = $nil; branch='rc/2022-07-14'; type = 'rc'; comment='2022-07-14' }
        @{ remote = $nil; branch='integrate/FOO-125_XYZ-1'; type = 'integration'; tickets=@('FOO-125','XYZ-1') }
    )
    
    $defaultBranches = @(
        @{ remote = 'origin'; branch='feature/FOO-123'; type = 'feature'; ticket='FOO-123' }
        @{ remote = 'origin'; branch='feature/FOO-124-comment'; type = 'feature'; ticket='FOO-124'; comment='comment' }
        @{ remote = 'origin'; branch='feature/FOO-124_FOO-125'; type = 'feature'; ticket='FOO-125'; parents=@('FOO-124') }
        @{ remote = 'origin'; branch='feature/FOO-76'; type = 'feature'; ticket='FOO-76' }
        @{ remote = 'origin'; branch='feature/XYZ-1-services'; type = 'feature'; ticket='XYZ-1'; comment='services' }
        @{ remote = 'origin'; branch='main'; type = 'service-line' }
        @{ remote = 'origin'; branch='rc/2022-07-14'; type = 'rc'; comment='2022-07-14' }
        @{ remote = 'origin'; branch='integrate/FOO-125_XYZ-1'; type = 'integration'; tickets=@('FOO-125','XYZ-1') }
    )
}

Describe 'git-add-upstream' {
    It 'works locally' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        Mock -CommandName Get-Configuration { return @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        . $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
        Mock -CommandName Assert-CleanWorkingDirectory { }
        
        # . $PSScriptRoot/config/git/Select-Branches.ps1
        # Mock -CommandName Select-Branches { return $noRemoteBranches }

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'merge feature/FOO-76 --quiet --commit --no-edit --no-squash' } { $Global:LASTEXITCODE = 0 }

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        $result = & ./git-add-upstream.ps1 -branchName 'rc/2022-07-14' -branches @('feature/FOO-76') -m ""
    }
    
    It 'works with a remote' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin _upstream' } { $Global:LASTEXITCODE = 0 }

        . $PSScriptRoot/config/git/Get-Configuration.ps1
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = 'main' } }

        . $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
        Mock -CommandName Assert-CleanWorkingDirectory { }
        
        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'merge feature/FOO-76 --quiet --commit --no-edit --no-squash' } { $Global:LASTEXITCODE = 0 }

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic HEAD:rc/2022-07-14 new-upstream-commit:origin/_upstream' } { $Global:LASTEXITCODE = 0 }

        $result = & ./git-add-upstream.ps1 -branchName 'rc/2022-07-14' -branches @('feature/FOO-76') -m ""
    }
}
