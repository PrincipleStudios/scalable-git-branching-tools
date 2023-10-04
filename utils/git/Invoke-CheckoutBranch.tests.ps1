BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Invoke-CheckoutBranch.psm1";
    Import-Module -Scope Local "$PSScriptRoot/Invoke-CheckoutBranch.mocks.psm1";
}

Describe 'Invoke-CheckoutBranch' {
    BeforeEach {
        Register-Framework
    }

    It 'throws if exit code is non-zero' {
        Initialize-CheckoutBranchFailed 'some-branch'
        { Invoke-CheckoutBranch some-branch -quiet } | Should -Throw
    }
    It 'does not throw if exit code is zero' {
        Initialize-CheckoutBranch 'some-branch'
        Invoke-CheckoutBranch some-branch -quiet
    }
}
