BeforeAll {
    . "$PSScriptRoot/config/core/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.psm1"

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Set-GitFiles.ps1
    Mock -CommandName Set-GitFiles {
        throw "Unexpected parameters for Set-GitFiles: $(@{ files = $files; commitMessage = $commitMessage; branchName = $branchName; remote = $remote; dryRun = $dryRun } | ConvertTo-Json)"
    }

    Mock -CommandName Invoke-PreserveBranch -ParameterFilter { $onlyIfError } {
        & $scriptBlock
    }

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/config/git/Invoke-WriteTree.ps1
    Mock -CommandName Invoke-WriteTree { throw "Unexpected parameters for Invoke-WriteTree: $treeEntries" }
}

Describe 'git-new' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.mocks.psm1";
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.mocks.psm1"
        Initialize-QuietMergeBranches
    }

    It 'handles standard functionality' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory

        # Mock git -ParameterFilter { ($args -join ' ') -eq 'config scaled-git.remote' } {}
        # Mock git -ParameterFilter { ($args -join ' ') -eq 'remote' } {}
        # Mock git -ParameterFilter { ($args -join ' ') -eq 'config scaled-git.upstreamBranch' } {}
        # Mock git -ParameterFilter { ($args -join ' ') -eq 'config scaled-git.defaultServiceLine' } { 'main' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch' } {
            Write-Output 'main'
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'clean -n' } {}
        Mock -CommandName Set-GitFiles -ParameterFilter {
            $files['feature/PS-100-some-work'] -eq 'main'
        } { 'new-commit' }
        Initialize-CreateBranch 'feature/PS-100-some-work' 'main'
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-CheckoutBranch 'feature/PS-100-some-work'

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
    }

    It 'creates a local branch when no remotes are configured' {
        Initialize-ToolConfiguration -noRemote

        Mock -CommandName Set-GitFiles -ParameterFilter {
            $files['feature/PS-100-some-work'] -eq 'main'
        } { 'new-commit' }
        Initialize-CleanWorkingDirectory
        Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'main'
        Initialize-CheckoutBranch 'feature/PS-100-some-work'
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-commit --quiet' } { $Global:LASTEXITCODE = 0 }

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
    }

    It 'creates a local branch from the specified branch when no remotes are configured' {
        Initialize-ToolConfiguration -noRemote
        Mock -CommandName Set-GitFiles -ParameterFilter {
            $files['feature/PS-600-some-work'] -eq 'infra/foo'
        } { 'new-commit' }
        Initialize-CleanWorkingDirectory
        Initialize-CreateBranch -branchName 'feature/PS-600-some-work' -source 'infra/foo'
        Initialize-CheckoutBranch 'feature/PS-600-some-work'
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-commit --quiet' } { $Global:LASTEXITCODE = 0 }

        & $PSScriptRoot/git-new.ps1 feature/PS-600-some-work -from 'infra/foo' -m 'some work'
    }

    It 'creates a remote branch when a remote is configured' {
        Initialize-ToolConfiguration
        Mock -CommandName Update-Git { }
        Mock -CommandName Set-GitFiles -ParameterFilter {
            $files['feature/PS-100-some-work'] -eq 'main'
        } { 'new-commit' }
        Initialize-CleanWorkingDirectory
        Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'origin/main'
        Initialize-CheckoutBranch 'feature/PS-100-some-work'
        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic feature/PS-100-some-work:refs/heads/feature/PS-100-some-work new-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -m 'some work'
    }

    It 'creates a remote branch when a remote is configured and an upstream branch is provided' {
        Initialize-ToolConfiguration
        Mock -CommandName Update-Git { }
        Mock -CommandName Set-GitFiles -ParameterFilter {
            $files['feature/PS-100-some-work'] -eq 'infra/foo'
        } { 'new-commit' }
        Initialize-CleanWorkingDirectory
        Initialize-CreateBranch -branchName 'feature/PS-100-some-work' -source 'origin/infra/foo'
        Initialize-CheckoutBranch 'feature/PS-100-some-work'
        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic feature/PS-100-some-work:refs/heads/feature/PS-100-some-work new-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }

        & $PSScriptRoot/git-new.ps1 feature/PS-100-some-work -from 'infra/foo' -m 'some work'
    }

}
