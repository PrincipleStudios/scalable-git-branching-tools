BeforeAll {
    . "$PSScriptRoot/../testing.ps1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-UpstreamBranches.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Select-UpstreamBranches.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../query-state.mocks.psm1"
}

Describe 'Select-UpstreamBranches' {
    BeforeEach {
        Register-Framework
    }

    It 'finds upstream branches from git and does not include remote by default' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        Initialize-UpstreamBranches @{
            'my-branch' = @("feature/FOO-123", "feature/XYZ-1-services")
        }

        $results = Select-UpstreamBranches my-branch
        $results | Should -Be @( 'feature/FOO-123', 'feature/XYZ-1-services' )
    }

    It 'finds upstream branches from git and includes remote when requested' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        Initialize-UpstreamBranches @{
            'my-branch' = @("feature/FOO-123", "feature/XYZ-1-services")
        }

        $results = Select-UpstreamBranches my-branch -includeRemote
        $results | Should -Be @( 'origin/feature/FOO-123', 'origin/feature/XYZ-1-services' )
    }

    It 'finds upstream branches from git (when there is one) and includes remote when requested' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        Initialize-UpstreamBranches @{
            'my-branch' = @("feature/FOO-123")
        }

        $results = Select-UpstreamBranches my-branch -includeRemote
        $results | Should -Be @( 'origin/feature/FOO-123' )
    }

    It 'allows some to be excluded' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        Initialize-UpstreamBranches @{
            'rc/1.1.0' = @("feature/FOO-123", "line/1.0")
        }

        $results = Select-UpstreamBranches rc/1.1.0 -includeRemote -exclude @('line/1.0')
        $results | Should -Be @( 'origin/feature/FOO-123' )
    }

    It 'allows some to be excluded even through ancestors' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        Initialize-UpstreamBranches @{
            'rc/1.1.0' = @("feature/FOO-123", "feature/XYZ-1-services")
            'feature/FOO-123' = @("line/1.0")
            'feature/XYZ-1-services' = @("line/1.0", "infra/some-service")
            'infra/some-service' = @("line/1.0")
        }

        $results = Select-UpstreamBranches rc/1.1.0 -includeRemote -recurse -exclude @('line/1.0')
        $results | Should -Be @( 'origin/feature/FOO-123', 'origin/feature/XYZ-1-services', 'origin/infra/some-service' )
    }

    It 'handles (invalid) recursiveness without failing' {
        Initialize-ToolConfiguration
        Initialize-UpstreamBranches @{
            'bad-recursive-branch-1' = @('bad-recursive-branch-2')
            'bad-recursive-branch-2' = @('bad-recursive-branch-1')
        }
        $results = Select-UpstreamBranches bad-recursive-branch-1 -recurse
        $results | Should -Be @( 'bad-recursive-branch-2' )
    }
}
