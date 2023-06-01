Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"

function Initialize-FetchUpstreamBranch() {
    $config = Get-Configuration
    if ($config.remote -ne $nil) {
        Invoke-MockGitModule -ModuleName 'Get-UpstreamBranch' -gitCli "fetch $($config.remote) $($config.upstreamBranch)"
    }
}

Export-ModuleMember -Function Initialize-FetchUpstreamBranch
