Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/Update-GitRemote.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Update-GitRemote' @PSBoundParameters
}

function Initialize-UpdateGitRemote($MockWith, [switch] $prune) {
    Mock -CommandName Write-Host -ModuleName 'Update-GitRemote' {}
    $config = Get-Configuration
    if ($config.remote -eq $nil) { return }
    $pruneArgs = $prune ? ' --prune' : ''
    Invoke-MockGit "fetch $($config.remote) -q$pruneArgs" -MockWith $MockWith
}
Export-ModuleMember -Function Initialize-UpdateGitRemote
