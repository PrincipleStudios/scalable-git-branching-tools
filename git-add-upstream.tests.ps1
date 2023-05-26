BeforeAll {
    . "$PSScriptRoot/config/testing/Lock-Git.mocks.ps1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    . $PSScriptRoot/config/git/Set-GitFiles.ps1
    Mock -CommandName Set-GitFiles {
        throw "Unexpected parameters for Set-GitFiles: $(@{ files = $files; commitMessage = $commitMessage; branchName = $branchName; remote = $remote; dryRun = $dryRun } | ConvertTo-Json)"
    }
}

Describe 'git-add-upstream' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/testing/Invoke-VerifyMock.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-BranchPushed.mocks.psm1"
        Initialize-QuietMergeBranches
    }

    It 'works on the current branch' {
        { git branch -a } | Should -Throw -Because 'we should have locked git down'

        Initialize-ToolConfiguration -noRemote

        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'rc/2022-07-14'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'feature/FOO-76'
        Initialize-PreserveBranchCleanup

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 'feature/FOO-76' -m ""
    }

    It 'works locally with multiple branches' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'rc/2022-07-14'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        $merge1Filter = Initialize-InvokeMergeSuccess 'feature/FOO-76'
        $merge2Filter = Initialize-InvokeMergeSuccess 'feature/FOO-84'
        Initialize-PreserveBranchCleanup

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -m ""

        Invoke-VerifyMock $merge1Filter -Times 1
        Invoke-VerifyMock $merge2Filter -Times 1
    }

    It 'works locally' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'feature/FOO-76'
        Initialize-PreserveBranchCleanup

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 -upstream 'feature/FOO-76' -branchName 'rc/2022-07-14' -m ""
    }

    It 'works locally with multiple branches' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        $merge1Filter = Initialize-InvokeMergeSuccess 'feature/FOO-76'
        $merge2Filter = Initialize-InvokeMergeSuccess 'feature/FOO-84'
        Initialize-PreserveBranchCleanup

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -branchName 'rc/2022-07-14' -m ""

        Invoke-VerifyMock $merge1Filter -Times 1
        Invoke-VerifyMock $merge2Filter -Times 1
    }

    It 'works with a remote' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchPushed 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-76'
        Initialize-PreserveBranchCleanup

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles -ParameterFilter { $files['rc/2022-07-14'] -eq "feature/FOO-76`nfeature/FOO-123`nfeature/XYZ-1-services" } { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic HEAD:rc/2022-07-14 new-upstream-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 @('feature/FOO-76') -branchName 'rc/2022-07-14' -m ""
    }

    It 'works with a remote when the target branch doesn''t exist locally' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchDoesNotExist 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-76'
        Initialize-PreserveBranchCleanup

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles -ParameterFilter { $files['rc/2022-07-14'] -eq "feature/FOO-76`nfeature/FOO-123`nfeature/XYZ-1-services" } { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic HEAD:rc/2022-07-14 new-upstream-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }

        & ./git-add-upstream.ps1 @('feature/FOO-76') -branchName 'rc/2022-07-14' -m ""
    }

    It 'outputs a helpful message if it fails' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'rc/2022-07-14'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchPushed 'rc/2022-07-14'

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Initialize-CheckoutBranch 'rc-old-commit'
        Initialize-InvokeMergeFailure 'feature/FOO-76'
        $mocks = Initialize-PreserveBranchCleanup

        & ./git-add-upstream.ps1 'feature/FOO-76' -m ""

        $LASTEXITCODE | Should -Be 1

        Should -Invoke -CommandName Write-Host -Times 1 -ParameterFilter { $Object -ne $nil -and $Object[0] -match 'git merge feature/FOO-76' }
        Invoke-VerifyMock $mocks -Times 1
    }

    It 'ensures the remote is up-to-date' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchNotPushed 'rc/2022-07-14'

        { & ./git-add-upstream.ps1 @('feature/FOO-76') -branchName 'rc/2022-07-14' -m "" }
            | Should -Throw "Branch rc/2022-07-14 has changes not pushed to origin/rc/2022-07-14. Please ensure changes are pushed (or reset) and try again."
    }

    It 'ensures the remote is tracked' {
        Initialize-ToolConfiguration
        Initialize-UpdateGit
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'my-branch'
        Initialize-UpstreamBranches @{ 'rc/2022-07-14' = @("feature/FOO-123","feature/XYZ-1-services") }
        Initialize-BranchNotPushed 'rc/2022-07-14'

        { & ./git-add-upstream.ps1 @('feature/FOO-76') -branchName 'rc/2022-07-14' -m "" }
            | Should -Throw "Branch rc/2022-07-14 has changes not pushed to origin/rc/2022-07-14. Please ensure changes are pushed (or reset) and try again."
    }

}
