BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-VerifyMock.psm1"
    . $PSScriptRoot/../TestUtils.ps1

    Mock -ModuleName Get-Configuration git {
        throw "Unmocked git command: $args"
    }

    function Invoke-MockGit([string] $gitCli, [scriptblock] $MockWith) {
        $result = New-VerifiableMock `
            -ModuleName 'Get-Configuration' `
            -CommandName git `
            -ParameterFilter $([scriptblock]::Create("(`$args -join ' ') -eq '$gitCli'"))
        Invoke-WrapMock $result -MockWith {
                $global:LASTEXITCODE = 0
                if ($MockWith -ne $nil) {
                    & $MockWith
                }
            }.GetNewClosure()
        return $result
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
