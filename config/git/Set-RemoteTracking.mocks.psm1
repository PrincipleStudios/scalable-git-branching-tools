Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/Set-RemoteTracking.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Set-RemoteTracking' @PSBoundParameters
}

function Initialize-SetRemoteTracking($branchName) {
    $remote = $(Get-Configuration).remote
    return Invoke-MockGit "branch --set-upstream-to=refs/heads/$($remote)/$($branchName) $($branchName)"
}
Export-ModuleMember -Function Initialize-SetRemoteTracking
