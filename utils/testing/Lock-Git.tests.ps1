
Describe 'Lock-Git' {
    BeforeAll {
        . "$PSScriptRoot/Lock-Git.ps1"
        Import-Module -Scope Local "$PSScriptRoot/Lock-Git.test-helper.psm1"
    }

    It 'prevents non-module code from calling git' {
        { git branch --show-current } | Should -Throw 'Unmocked git command: branch --show-current'
    }
    It 'prevents module code from calling git' {
        { Invoke-LockGitTestHelper } | Should -Throw 'Unmocked git command in module Lock-Git.test-helper: branch --show-current'
    }
}
