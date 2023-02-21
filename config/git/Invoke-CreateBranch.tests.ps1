BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/Invoke-CreateBranch.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Invoke-CreateBranch.mocks.psm1"

    Mock git {
        throw "Unmocked git command: $args"
    }
}

Describe 'Invoke-CreateBranch' {
    It 'throws if exit code is non-zero' {
        Initialize-CreateBranchFailed -branchName 'some-branch' -source 'source'
        { Invoke-CreateBranch some-branch source } | Should -Throw
    }
    It 'does not throw if exit code is zero' {
        Initialize-CreateBranch -branchName 'some-branch' -source 'source'
        Invoke-CreateBranch some-branch source
    }
}
