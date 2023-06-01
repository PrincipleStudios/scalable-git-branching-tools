Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/Update-Git.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Update-Git' @PSBoundParameters
}

function Initialize-UpdateGit($MockWith, [switch] $prune) {
    Mock -CommandName Write-Host -ModuleName 'Update-Git' {}
    $config = Get-Configuration
    if ($config.remote -eq $nil) { return }
    $pruneArgs = $prune ? ' --prune' : ''
    Invoke-MockGit "fetch $($config.remote) -q $pruneArgs" -MockWith $MockWith
}
Export-ModuleMember -Function Initialize-UpdateGit
