Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"

function Set-RemoteTracking([String]$branchName) {
    $config = Get-Configuration
    git branch --set-upstream-to="refs/remotes/$($config.remote)/$($branchName)" $($branchName)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not set  '$branchName' from '$($source)'"
    }
}
Export-ModuleMember -Function Set-RemoteTracking
