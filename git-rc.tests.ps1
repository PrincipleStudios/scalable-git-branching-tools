BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    # Mock -CommandName Write-Host {}

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


Describe 'git-rc' {
    It 'handles standard functionality' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream' } }
        
        . $PSScriptRoot/config/git/Update-Git.ps1
        Mock -CommandName Update-Git { }
        
        . $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
        Mock -CommandName Assert-CleanWorkingDirectory { }
        
        . $PSScriptRoot/config/git/Select-Branches.ps1
        Mock -CommandName Select-Branches { return $defaultBranches }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch rc/2022-07-28 origin/feature/FOO-123 --quiet' } {
            $global:LASTEXITCODE = 0;
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc/2022-07-28 --quiet' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'merge origin/feature/FOO-124-comment --quiet --commit --no-edit --no-squash' } {}
        Mock git -ParameterFilter { ($args -join ' ') -eq 'merge origin/integrate/FOO-125_XYZ-1 --quiet --commit --no-edit --no-squash' } {}
        . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
        Mock -CommandName Set-UpstreamBranches -ParameterFilter { 
            $branchName -eq 'rc/2022-07-28' `
                -AND ($upstreamBranches -join ' ') -eq 'feature/FOO-123 feature/FOO-124-comment integrate/FOO-125_XYZ-1'
        } {}

        & $PSScriptRoot/git-rc.ps1 -tickets FOO-123,FOO-124 -branches integrate/FOO-125_XYZ-1 -m 'New RC' -label '2022-07-28'
    }
}
