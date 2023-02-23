BeforeAll {
    . "$PSScriptRoot/../core/Lock-Git.mocks.ps1"
    . $PSScriptRoot/Select-UpstreamBranches.ps1
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.mocks.psm1"
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Select-UpstreamBranches' {
    It 'finds upstream branches from git and does not include remote by default' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        $config = @{ remote = 'origin'; upstreamBranch = 'my-upstream' }

        Initialize-GitFile 'origin/my-upstream' 'my-branch' @("feature/FOO-123", "feature/XYZ-1-services")

        $results = Select-UpstreamBranches my-branch -config $config
        $results | Should -Be @( 'feature/FOO-123', 'feature/XYZ-1-services' )
    }

    It 'finds upstream branches from git and includes remote when requested' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        $config = @{ remote = 'origin'; upstreamBranch = 'my-upstream' }

        Initialize-GitFile 'origin/my-upstream' 'my-branch' @("feature/FOO-123", "feature/XYZ-1-services")

        $results = Select-UpstreamBranches my-branch -includeRemote -config $config
        $results | Should -Be @( 'origin/feature/FOO-123', 'origin/feature/XYZ-1-services' )
    }

    It 'finds upstream branches from git (when there is one) and includes remote when requested' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        $config = @{ remote = 'origin'; upstreamBranch = 'my-upstream' }

        Initialize-GitFile 'origin/my-upstream' 'my-branch' @("feature/FOO-123")

        $results = Select-UpstreamBranches my-branch -includeRemote -config $config
        $results | Should -Be @( 'origin/feature/FOO-123' )
    }

    It 'allows some to be excluded' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        $config = @{ remote = 'origin'; upstreamBranch = 'my-upstream' }

        Initialize-GitFile 'origin/my-upstream' 'rc/1.1.0' @("feature/FOO-123", "line/1.0")

        $results = Select-UpstreamBranches rc/1.1.0 -includeRemote -exclude @('line/1.0') -config $config
        $results | Should -Be @( 'origin/feature/FOO-123' )
    }

    It 'allows some to be excluded even through ancestors' {
        Initialize-ToolConfiguration -upstreamBranchName 'my-upstream'
        $config = @{ remote = 'origin'; upstreamBranch = 'my-upstream' }

        Initialize-GitFile 'origin/my-upstream' 'rc/1.1.0' @("feature/FOO-123", "feature/XYZ-1-services")
        Initialize-GitFile 'origin/my-upstream' 'feature/FOO-123' @("line/1.0")
        Initialize-GitFile 'origin/my-upstream' 'feature/XYZ-1-services' @("line/1.0", "infra/some-service")
        Initialize-GitFile 'origin/my-upstream' 'infra/some-service' @("line/1.0")

        $results = Select-UpstreamBranches rc/1.1.0 -includeRemote -recurse -exclude @('line/1.0') -config $config
        $results | Should -Be @( 'origin/feature/FOO-123', 'origin/feature/XYZ-1-services', 'origin/infra/some-service' )
    }
}
