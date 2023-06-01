BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-WriteTree.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-Branches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.mocks.psm1"

    Initialize-QuietMergeBranches

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    Lock-InvokeWriteTree
    Lock-SetMultipleUpstreamBranches

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
    Context 'without remote' {
        BeforeAll {
            Initialize-ToolConfiguration -noRemote
            Initialize-AnyUpstreamBranches
            Initialize-UpstreamBranches @{}
        }

        It 'handles standard functionality' {
            Initialize-CleanWorkingDirectory
            Initialize-SelectBranches $noRemoteBranches
            Initialize-CreateBranch 'rc/2022-07-28' 'feature/FOO-123'
            Initialize-CheckoutBranch 'rc/2022-07-28'
            Initialize-InvokeMergeSuccess 'feature/FOO-124-comment'
            Initialize-InvokeMergeSuccess 'integrate/FOO-125_XYZ-1'

            Initialize-SetMultipleUpstreamBranches @{ 'rc/2022-07-28' = @( 'feature/FOO-123', 'feature/FOO-124-comment', 'integrate/FOO-125_XYZ-1' ) } 'New RC' 'upstream-commit'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream upstream-commit' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28'
        }
    }

    Context 'with remote' {
        BeforeAll {
            Initialize-ToolConfiguration
            Initialize-UpdateGit
            Initialize-AnyUpstreamBranches
        }

        It 'handles standard functionality' {
            Initialize-UpdateGit
            Initialize-CleanWorkingDirectory
            Initialize-SelectBranches $defaultBranches
            Initialize-CreateBranch 'rc/2022-07-28' 'origin/feature/FOO-123'
            Initialize-CheckoutBranch 'rc/2022-07-28'
            Initialize-InvokeMergeSuccess 'origin/feature/FOO-124-comment'
            Initialize-InvokeMergeSuccess 'origin/integrate/FOO-125_XYZ-1'
            Initialize-SetMultipleUpstreamBranches @{ 'rc/2022-07-28' = @( 'feature/FOO-123', 'feature/FOO-124-comment', 'integrate/FOO-125_XYZ-1' ) } 'New RC' 'upstream-commit'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin rc/2022-07-28:refs/heads/rc/2022-07-28 upstream-commit:refs/heads/_upstream --atomic' } { $Global:LASTEXITCODE = 0 }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28'
        }

        It 'allows a null comment' {
            Initialize-UpdateGit
            Initialize-CleanWorkingDirectory
            Initialize-SelectBranches $defaultBranches
            Initialize-CreateBranch 'rc/2022-07-28' 'origin/feature/FOO-123'
            Initialize-CheckoutBranch 'rc/2022-07-28'
            Initialize-InvokeMergeSuccess 'origin/feature/FOO-124-comment'
            Initialize-InvokeMergeSuccess 'origin/integrate/FOO-125_XYZ-1'
            Initialize-SetMultipleUpstreamBranches @{ 'rc/2022-07-28' = @( 'feature/FOO-123', 'feature/FOO-124-comment', 'integrate/FOO-125_XYZ-1' ) } 'Add branch rc/2022-07-28' 'upstream-commit'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin rc/2022-07-28:refs/heads/rc/2022-07-28 upstream-commit:refs/heads/_upstream --atomic' } { $Global:LASTEXITCODE = 0 }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m $nil -branchName 'rc/2022-07-28'
        }

        It 'simplifies upstream before creating the rc' {
            Initialize-UpstreamBranches @{
                'integrate/FOO-125_XYZ-1' = @( 'feature/FOO-125', 'feature/XYZ-1' )
            }
            Initialize-UpdateGit
            Initialize-CleanWorkingDirectory
            Initialize-SelectBranches $defaultBranches
            Initialize-CreateBranch 'rc/2022-07-28' 'origin/feature/FOO-123'
            Initialize-CheckoutBranch 'rc/2022-07-28'
            Initialize-InvokeMergeSuccess 'origin/integrate/FOO-125_XYZ-1'
            Initialize-SetMultipleUpstreamBranches @{ 'rc/2022-07-28' = @( 'feature/FOO-123', 'integrate/FOO-125_XYZ-1' ) } 'New RC' 'upstream-commit'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin rc/2022-07-28:refs/heads/rc/2022-07-28 upstream-commit:refs/heads/_upstream --atomic' } { $Global:LASTEXITCODE = 0 }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

            & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-125,feature/XYZ-1,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28'
        }

        It 'does not push if there is a failure while merging' {
            Initialize-UpdateGit
            Initialize-CleanWorkingDirectory
            Initialize-SelectBranches $defaultBranches
            Initialize-CreateBranch 'rc/2022-07-28' 'origin/feature/FOO-123'
            Initialize-CheckoutBranch 'rc/2022-07-28'
            Initialize-InvokeMergeFailure 'origin/feature/FOO-124-comment'
            Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -D rc/2022-07-28' } { $Global:LASTEXITCODE = 0 }

            { & $PSScriptRoot/git-rc.ps1 -branches feature/FOO-123,feature/FOO-124-comment,integrate/FOO-125_XYZ-1 -m 'New RC' -branchName 'rc/2022-07-28' } | Should -Throw
        }
    }

}
