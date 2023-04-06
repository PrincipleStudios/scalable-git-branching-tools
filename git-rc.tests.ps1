BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-WriteTree.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Set-UpstreamBranches.ps1
    Mock -CommandName Set-UpstreamBranches { throw "Unexpected parameters for Set-UpstreamBranches: $branchName $upstreamBranches $commitMessage" }

    Lock-InvokeWriteTree

    Mock -CommandName Invoke-PreserveBranch {
        & $scriptBlock
        & $cleanup
    }

    $noRemoteBranches = @(
        'feature/FOO-123'
        'feature/FOO-124-comment'
        'feature/FOO-124_FOO-125'
        'feature/FOO-76'
        'feature/XYZ-1-services'
        'main'
        'rc/2022-07-14'
        'integrate/FOO-125_XYZ-1'
    )

    $defaultBranches = $noRemoteBranches | ForEach-Object { "origin/$_" }
}


Describe 'git-rc' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Select-Branches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
        Initialize-QuietMergeBranches
    }

    It 'handles standard functionality' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-SelectBranches $defaultBranches
        Initialize-CreateBranch 'rc/2022-07-28' 'origin/feature/FOO-123'
        Initialize-CheckoutBranch 'rc/2022-07-28'
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
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-SelectBranches $noRemoteBranches
        Initialize-CreateBranch 'rc/2022-07-28' 'feature/FOO-123'
        Initialize-CheckoutBranch 'rc/2022-07-28'
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
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-SelectBranches $defaultBranches
        Initialize-CreateBranch 'rc/2022-07-28' 'origin/feature/FOO-123'
        Initialize-CheckoutBranch 'rc/2022-07-28'
        Initialize-InvokeMergeFailure 'origin/feature/FOO-124-comment'
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

        { & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28' } | Should -Throw
    }

    It 'can skip the initial fetch' {
        Initialize-ToolConfiguration
        Initialize-CleanWorkingDirectory
        Initialize-SelectBranches $defaultBranches
        Initialize-CreateBranch 'rc/2022-07-28' 'origin/feature/FOO-123'
        Initialize-CheckoutBranch 'rc/2022-07-28'
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
