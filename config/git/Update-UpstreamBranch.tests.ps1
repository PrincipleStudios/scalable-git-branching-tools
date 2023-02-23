BeforeAll {
    . "$PSScriptRoot/../core/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Update-UpstreamBranch.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Update-UpstreamBranch.mocks.psm1"
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Update-UpstreamBranch' {
    It 'pushes a commit to the remote' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        Initialize-UpdateUpstreamBranch 'new-COMMIT'

        Update-UpstreamBranch -commitish 'new-COMMIT'
    }
    It 'updates the local branch if no remote in config' {
        Initialize-ToolConfiguration -noRemote -upstreamBranchName 'my-upstream'
        Initialize-UpdateUpstreamBranch 'new-COMMIT'

        Update-UpstreamBranch -commitish 'new-COMMIT'
    }
    It 'throws on a failure' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        Initialize-UpdateUpstreamBranch 'new-COMMIT' -fail

        { Update-UpstreamBranch -commitish 'new-COMMIT' } | Should -Throw 'Failed to update remote branch origin/my-upstream; another dev must have been updating it. Try again later.'
    }
}
