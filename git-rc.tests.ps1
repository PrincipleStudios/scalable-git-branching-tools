BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

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
}


Describe 'git-rc' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
        Initialize-QuietMergeBranches
    }

    It 'handles standard functionality' {
        Initialize-ToolConfiguration

        . $PSScriptRoot/config/git/Update-Git.ps1
        Mock -CommandName Update-Git { }

        Initialize-CleanWorkingDirectory

        . $PSScriptRoot/config/git/Select-Branches.ps1
        Mock -CommandName Select-Branches { return $defaultBranches }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch rc/2022-07-28 origin/feature/FOO-123 --quiet --no-track' } {
            $global:LASTEXITCODE = 0;
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc/2022-07-28 --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-124-comment'
        Initialize-InvokeMergeSuccess 'origin/integrate/FOO-125_XYZ-1'
        . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
        Mock -CommandName Set-UpstreamBranches -ParameterFilter {
            $branchName -eq 'rc/2022-07-28' `
                -AND ($upstreamBranches -join ' ') -eq 'feature/FOO-123 feature/FOO-124-comment integrate/FOO-125_XYZ-1'
        } {}
        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin rc/2022-07-28:refs/heads/rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

        & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28'
    }

    It 'handles no remote' {
        Initialize-ToolConfiguration -noRemote

        . $PSScriptRoot/config/git/Update-Git.ps1
        Mock -CommandName Update-Git { }

        Initialize-CleanWorkingDirectory

        . $PSScriptRoot/config/git/Select-Branches.ps1
        Mock -CommandName Select-Branches { return $noRemoteBranches }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch rc/2022-07-28 feature/FOO-123 --quiet --no-track' } {
            $global:LASTEXITCODE = 0;
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc/2022-07-28 --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeSuccess 'feature/FOO-124-comment'
        Initialize-InvokeMergeSuccess 'integrate/FOO-125_XYZ-1'
        . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
        Mock -CommandName Set-UpstreamBranches -ParameterFilter {
            $branchName -eq 'rc/2022-07-28' `
                -AND ($upstreamBranches -join ' ') -eq 'feature/FOO-123 feature/FOO-124-comment integrate/FOO-125_XYZ-1'
        } {}

        & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28'
    }

    It 'does not push if there is a failure while merging' {
        Initialize-ToolConfiguration

        . $PSScriptRoot/config/git/Update-Git.ps1
        Mock -CommandName Update-Git { }

        Initialize-CleanWorkingDirectory

        . $PSScriptRoot/config/git/Select-Branches.ps1
        Mock -CommandName Select-Branches { return $defaultBranches }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch rc/2022-07-28 origin/feature/FOO-123 --quiet --no-track' } {
            $global:LASTEXITCODE = 0;
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc/2022-07-28 --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeFailure 'origin/feature/FOO-124-comment'
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

        { & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28' } | Should -Throw
    }

    It 'can skip the initial fetch' {
        Initialize-ToolConfiguration

        . $PSScriptRoot/config/git/Update-Git.ps1
        Mock -CommandName Update-Git { throw 'should not call Update-Git' }

        Initialize-CleanWorkingDirectory

        . $PSScriptRoot/config/git/Select-Branches.ps1
        Mock -CommandName Select-Branches { return $defaultBranches }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch rc/2022-07-28 origin/feature/FOO-123 --quiet --no-track' } {
            $global:LASTEXITCODE = 0;
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc/2022-07-28 --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-124-comment'
        Initialize-InvokeMergeSuccess 'origin/integrate/FOO-125_XYZ-1'
        . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
        Mock -CommandName Set-UpstreamBranches -ParameterFilter {
            $branchName -eq 'rc/2022-07-28' `
                -AND ($upstreamBranches -join ' ') -eq 'feature/FOO-123 feature/FOO-124-comment integrate/FOO-125_XYZ-1'
        } {}
        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin rc/2022-07-28:refs/heads/rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

        & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28' -noFetch
    }

}
