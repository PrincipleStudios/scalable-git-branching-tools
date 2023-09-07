BeforeAll {
    . "$PSScriptRoot/../../config/testing/Lock-Git.mocks.ps1"
    Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../../config/testing/Invoke-MockGitModule.psm1"
    . $PSScriptRoot/../../config/TestUtils.ps1

    function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
        return Invoke-MockGitModule -ModuleName 'Configuration' @PSBoundParameters
    }
}

Describe 'Get-Configuration' {

    It 'Defaults values' {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote'
        Invoke-MockGit 'config scaled-git.defaultServiceLine'
        Invoke-MockGit 'rev-parse --verify main -q' { 'some-hash' }
        Invoke-MockGit 'config scaled-git.upstreamBranch'
        Invoke-MockGit 'config scaled-git.atomicPushEnabled'

        Get-Configuration | Should-BeObject @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = 'main'; atomicPushEnabled = $true }
    }

    It 'Defaults values with no main branch' {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote'
        Invoke-MockGit 'config scaled-git.defaultServiceLine'
        Invoke-MockGit 'rev-parse --verify main -q' { $global:LASTEXITCODE = 128 }
        Invoke-MockGit 'config scaled-git.upstreamBranch'
        Invoke-MockGit 'config scaled-git.atomicPushEnabled'

        Get-Configuration | Should-BeObject @{ remote = $nil; upstreamBranch = '_upstream'; defaultServiceLine = $nil; atomicPushEnabled = $true }
    }

    It 'Defaults values with a remote main branch' {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote' { 'origin' }
        Invoke-MockGit 'config scaled-git.defaultServiceLine'
        Invoke-MockGit 'rev-parse --verify origin/main -q' { 'some-hash'}
        Invoke-MockGit 'config scaled-git.upstreamBranch'
        Invoke-MockGit 'config scaled-git.atomicPushEnabled'

        Get-Configuration | Should-BeObject @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = 'main'; atomicPushEnabled = $true }
    }

    It 'Overrides defaults' {
        Invoke-MockGit 'config scaled-git.remote' { 'github' }
        Invoke-MockGit 'config scaled-git.upstreamBranch' { 'upstream-config' }
        Invoke-MockGit 'config scaled-git.defaultServiceLine' { 'trunk' }
        Invoke-MockGit 'config scaled-git.atomicPushEnabled' { $false }

        Get-Configuration | Should-BeObject @{ remote = 'github'; upstreamBranch = 'upstream-config'; defaultServiceLine = 'trunk'; atomicPushEnabled = $false }
    }
}
