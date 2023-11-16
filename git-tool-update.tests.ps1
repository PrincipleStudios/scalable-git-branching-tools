BeforeAll {
    . "$PSScriptRoot/utils/testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/utils/framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/utils/git.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/migration/Invoke-Migration.mocks.psm1"

    Mock -CommandName git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify HEAD' } {
        $Global:LASTEXITCODE = 0
        'old-commit'
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host { }
}

Describe 'git-tool-update' {
    BeforeEach {
        Register-Framework
    }

    It 'prevents working on a branch with changes' {
        Initialize-DirtyWorkingDirectory

        { & $PSScriptRoot/git-tool-update.ps1 } | Should -Throw 'Git working directory is not clean.'
    }

    It 'requires a branchName parameter when not on a branch' {
        Initialize-CleanWorkingDirectory
        Initialize-NoCurrentBranch
        Initialize-PreserveBranchCleanup -detachedHead 'old-commit'

        { & $PSScriptRoot/git-tool-update.ps1 } | Should -Throw 'Tools are not currently on a branch - you must specify one via -sourceBranch.'
    }

    It 'fails if it cannot fast-forward' {
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'main'
        Invoke-MockGit 'pull --ff-only' -fail
        Initialize-PreserveBranchCleanup

        { & $PSScriptRoot/git-tool-update.ps1 } | Should -Throw 'Could not pull latest for main'
    }

    It 'checks to see if any migrations are necessary and re-runs init' {
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'main'
        $verifyMigrations = Initialize-RunNoMigrations 'old-commit'
        $mockPull = Invoke-MockGit 'pull --ff-only'
        Initialize-PreserveBranchNoCleanup
        Mock -CommandName git -ParameterFilter { ($args -join ' ') -like 'config alias.*' } -MockWith { $Global:LASTEXITCODE = 0 }
        Invoke-MockGit 'version' -MockWith 'git version 2.41.0'

        & $PSScriptRoot/git-tool-update.ps1

        Invoke-VerifyMock $verifyMigrations -Times 1
        Invoke-VerifyMock $mockPull -Times 1
    }

    It 'allows specifying the branch and will fail if it doesn''t exist' {
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'main'
        Initialize-PreserveBranchCleanup
        Invoke-MockGit 'checkout feature/test' -fail

        { & $PSScriptRoot/git-tool-update.ps1 -sourceBranch feature/test } | Should -Throw 'Could not switch to feature/test'
    }

    It 'allows specifying the branch' {
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'main'
        $verifyMigrations = Initialize-RunNoMigrations 'old-commit'
        $mockCheckout = Invoke-MockGit 'checkout feature/test'
        $mockPull = Invoke-MockGit 'pull --ff-only'
        Initialize-PreserveBranchNoCleanup
        Mock -CommandName git -ParameterFilter { ($args -join ' ') -like 'config alias.*' } -MockWith { $Global:LASTEXITCODE = 0 }
        Invoke-MockGit 'version' -MockWith 'git version 2.41.0'

        & $PSScriptRoot/git-tool-update.ps1 -sourceBranch feature/test

        Invoke-VerifyMock $verifyMigrations -Times 1
        Invoke-VerifyMock $mockCheckout -Times 1
        Invoke-VerifyMock $mockPull -Times 1
    }
    

    It 'allows running the script for mac' {
        Initialize-CleanWorkingDirectory
        Initialize-CurrentBranch 'main'
        $verifyMigrations = Initialize-RunNoMigrations 'old-commit'
        $mockPull = Invoke-MockGit 'pull --ff-only'
        Initialize-PreserveBranchNoCleanup
        Mock -CommandName git -ParameterFilter { ($args -join ' ') -like 'config alias.*' } -MockWith { $Global:LASTEXITCODE = 0 }
        Invoke-MockGit 'version' -MockWith 'git version 2.41.0 (Apple Git-143)'

        & $PSScriptRoot/git-tool-update.ps1

        Invoke-VerifyMock $verifyMigrations -Times 1
        Invoke-VerifyMock $mockPull -Times 1
    }
}
