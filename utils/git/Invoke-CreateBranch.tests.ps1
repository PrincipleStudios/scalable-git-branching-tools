BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Invoke-CreateBranch.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Invoke-CreateBranch.mocks.psm1"

    # Register-Framework
}

Describe 'Invoke-CreateBranch' {
    It 'throws if exit code is non-zero' {
        Initialize-CreateBranchFailed -branchName 'some-branch' -source 'source'
        { Invoke-CreateBranch some-branch source } | Should -Throw
    }
    It 'does not throw if exit code is zero' {
        Initialize-CreateBranch -branchName 'some-branch1' -source 'source'
        Invoke-CreateBranch some-branch1 source
    }
}
