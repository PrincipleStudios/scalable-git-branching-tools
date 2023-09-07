BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-VerifyMock.psm1"
}

Describe 'Get-UpstreamBranch' {
    It 'computes the upstream tracking branch name' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream' -remote 'github'
        Get-UpstreamBranch | Should -Be 'github/my-upstream'
    }
    It 'can handle no remote' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream' -noRemote
        Get-UpstreamBranch | Should -Be 'my-upstream'
    }
    It 'fetches if requested' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream' -remote 'github'
        $mock = Initialize-FetchUpstreamBranch

        Get-UpstreamBranch -fetch | Should -Be 'github/my-upstream'
        Invoke-VerifyMock $mock -Times 1
    }
}
