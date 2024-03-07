BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-DownstreamBranches.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
}

Describe 'Select-DownstreamBranches' {
    BeforeEach {
        Register-Framework
        Initialize-ToolConfiguration

        Initialize-AllUpstreamBranches @{
            'integrate/FOO-123_XYZ-1' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-124' = @("feature/FOO-123")
            'feature/FOO-123' = @("main")
            'feature/XYZ-1-services' = @("main")
            'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")

            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }
    }

    It 'finds downstream branches' {
        $results = Select-DownstreamBranches 'main'
        $results.Length | Should -Be 2
        $results | Should -Contain 'feature/FOO-123'
        $results | Should -Contain 'feature/XYZ-1-services'
    }

    It 'allows some downstreams to be excluded' {
        $results = Select-DownstreamBranches 'main' -exclude @('feature/FOO-123')
        $results | Should -Be @( 'feature/XYZ-1-services' )
    }

    It 'finds recursive downstream branches' {
        $results = Select-DownstreamBranches 'main' -recurse
        $results.Length | Should -Be 5
        $results | Should -Contain 'feature/FOO-123'
        $results | Should -Contain 'feature/XYZ-1-services'
        $results | Should -Contain 'feature/FOO-124'
        $results | Should -Contain 'integrate/FOO-123_XYZ-1'
        $results | Should -Contain 'rc/1.1.0'
    }

    It 'allows some to be excluded even through ancestors' {
        $results = Select-DownstreamBranches 'main' -recurse -exclude @('rc/1.1.0')
        $results.Length | Should -Be 4
        $results | Should -Contain 'feature/FOO-123'
        $results | Should -Contain 'feature/XYZ-1-services'
        $results | Should -Contain 'feature/FOO-124'
        $results | Should -Contain 'integrate/FOO-123_XYZ-1'
    }

    It 'handles (invalid) recursiveness without failing' {
        $results = Select-DownstreamBranches bad-recursive-branch-1 -recurse
        $results | Should -Be @( 'bad-recursive-branch-2' )
    }
}
