BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    . $PSScriptRoot/Get-UpstreamBranch.ps1

    Mock git {
        throw "Unmocked git command: $args"
    }
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
        Mock git -ParameterFilter { ($args -join ' ') -eq 'fetch github my-upstream' } -Verifiable { $global:LASTEXITCODE = 0 }

        Get-UpstreamBranch -fetch | Should -Be 'github/my-upstream'
        Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'fetch github my-upstream' } -Times 1
    }
}
