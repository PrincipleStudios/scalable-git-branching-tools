Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/Update-Git.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Update-Git' @PSBoundParameters
}

function Initialize-UpdateGit($MockWith) {
    Mock -CommandName Write-Host -ModuleName 'Update-Git' {}
    $config = Get-Configuration
    if ($config.remote -eq $nil) { return }
    Invoke-MockGit "fetch $($config.remote) -q" -MockWith $MockWith
}
Export-ModuleMember -Function Initialize-UpdateGit
