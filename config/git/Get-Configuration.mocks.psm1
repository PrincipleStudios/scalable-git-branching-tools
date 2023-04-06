Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Get-Configuration' @PSBoundParameters
}

function Initialize-ToolConfiguration(
    [switch]$noRemote,
    [string]$remote = 'origin',
    [string]$defaultServiceLine = 'main',
    [string]$upstreamBranchName = '_upstream',
    [switch]$noAtomicPush
) {
    if ($noRemote) {
        Invoke-MockGit 'config scaled-git.remote'
        Invoke-MockGit 'remote'
    } else {
        Invoke-MockGit 'config scaled-git.remote' $remote
    }

    Invoke-MockGit 'config scaled-git.upstreamBranch' $upstreamBranchName
    Invoke-MockGit 'config scaled-git.defaultServiceLine' -MockWith $defaultServiceLine
    Invoke-MockGit 'config scaled-git.atomicPushEnabled' -MockWith (-not $noAtomicPush)
}

Export-ModuleMember -Function Initialize-ToolConfiguration
