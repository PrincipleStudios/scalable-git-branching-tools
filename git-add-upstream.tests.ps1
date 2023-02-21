BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}

    . $PSScriptRoot/config/git/Invoke-PreserveBranch.mocks.ps1

    . $PSScriptRoot/config/git/Set-GitFiles.ps1
    Mock -CommandName Set-GitFiles {
        throw "Unexpected parameters for Set-GitFiles: $(@{ files = $files; commitMessage = $commitMessage; branchName = $branchName; remote = $remote; dryRun = $dryRun } | ConvertTo-Json)"
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
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.mocks.psm1"
        Initialize-QuietMergeBranches
        Import-Module -Scope Local "$PSScriptRoot/config/core/Invoke-VerifyMock.psm1"
    }

    It 'works on the current branch' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory

        Mock git -ParameterFilter {($args -join ' ') -eq 'branch --show-current'} {
            'rc/2022-07-14'
        }

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeSuccess 'feature/FOO-76'

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        $result = & ./git-add-upstream.ps1 'feature/FOO-76' -m ""
    }

    It 'works locally with multiple branches' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory

        Mock git -ParameterFilter {($args -join ' ') -eq 'branch --show-current'} {
            'rc/2022-07-14'
        }

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        $merge1Filter = Initialize-InvokeMergeSuccess 'feature/FOO-76'
        $merge2Filter = Initialize-InvokeMergeSuccess 'feature/FOO-84'

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        $result = & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -m ""

        Invoke-VerifyMock $merge1Filter -Times 1
        Invoke-VerifyMock $merge2Filter -Times 1
    }

    It 'works locally' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeSuccess 'feature/FOO-76'

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        $result = & ./git-add-upstream.ps1 'feature/FOO-76' -branchName 'rc/2022-07-14' -m ""
    }

    It 'works locally with multiple branches' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        $merge1Filter = Initialize-InvokeMergeSuccess 'feature/FOO-76'
        $merge2Filter = Initialize-InvokeMergeSuccess 'feature/FOO-84'

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f _upstream new-upstream-commit' } { $Global:LASTEXITCODE = 0 }

        $result = & ./git-add-upstream.ps1 'feature/FOO-76','feature/FOO-84' -branchName 'rc/2022-07-14' -m ""

        Invoke-VerifyMock $merge1Filter -Times 1
        Invoke-VerifyMock $merge2Filter -Times 1
    }

    It 'works with a remote' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin -q' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch origin _upstream' } { $Global:LASTEXITCODE = 0 }

        Initialize-ToolConfiguration
        Initialize-CleanWorkingDirectory

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeSuccess 'origin/feature/FOO-76'

        . $PSScriptRoot/config/git/Set-GitFiles.ps1
        Mock -CommandName Set-GitFiles -ParameterFilter { $files['rc/2022-07-14'] -eq "feature/FOO-76`nfeature/FOO-123`nfeature/XYZ-1-services" } { 'new-upstream-commit' }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin --atomic HEAD:rc/2022-07-14 new-upstream-commit:refs/heads/_upstream' } { $Global:LASTEXITCODE = 0 }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'branch -f rc/2022-07-14 HEAD' } { $Global:LASTEXITCODE = 0 }

        $result = & ./git-add-upstream.ps1 @('feature/FOO-76') -branchName 'rc/2022-07-14' -m ""
    }

    It 'outputs a helpful message if it fails' {
        Initialize-ToolConfiguration -noRemote
        Initialize-CleanWorkingDirectory


        Mock git -ParameterFilter {($args -join ' ') -eq 'branch --show-current'} {
            'rc/2022-07-14'
        }

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p _upstream:rc/2022-07-14'} {
            "feature/FOO-123"
            "feature/XYZ-1-services"
        }

        Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify rc/2022-07-14 -q' } { 'rc-old-commit' }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'checkout rc-old-commit --quiet' } { $Global:LASTEXITCODE = 0 }
        Initialize-InvokeMergeFailure 'feature/FOO-76'

        $invokePreserveBranch.cleanupCounter = 0

        $result = & ./git-add-upstream.ps1 'feature/FOO-76' -m ""

        $LASTEXITCODE | Should -Be 1
        $invokePreserveBranch.cleanupCounter | Should -Be 1

        Should -Invoke -CommandName Write-Host -Times 1 -ParameterFilter { $Object -ne $nil -and $Object[0] -match 'git merge feature/FOO-76' }
    }

}
