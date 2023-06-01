BeforeAll {
    . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Compress-UpstreamBranches.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-UpstreamBranches.mocks.psm1"
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Compress-UpstreamBranches' {
    BeforeAll {
        Initialize-ToolConfiguration
        Initialize-UpstreamBranches @{
            'my-branch' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-123' = @('main')
            'feature/XYZ-1-services' = @('main')
            'main' = @()

            # These are bad examples - they shouldn't happen!
            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }

    }

    It 'does not reduce any if none can be reduced' {
        Compress-UpstreamBranches my-branch | Should -Be @( 'my-branch' )
        Compress-UpstreamBranches @("feature/FOO-123", "feature/XYZ-1-services") | Should -Be @("feature/FOO-123", "feature/XYZ-1-services")
    }

    It 'reduces redundant branches' {
        Compress-UpstreamBranches @("my-branch", "feature/XYZ-1-services") | Should -Be @("my-branch")
    }

    It 'allows an empty list' {
        Compress-UpstreamBranches @() | Should -Be @()
    }

    It 'does not eliminate all recursive branches' {
        Compress-UpstreamBranches @('bad-recursive-branch-1', 'bad-recursive-branch-2') | Should -Be @('bad-recursive-branch-2')
    }

}
