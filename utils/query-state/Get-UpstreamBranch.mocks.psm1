Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"

function Initialize-FetchUpstreamBranch() {
    $config = Get-Configuration
    if ($config.remote -ne $nil) {
        Invoke-MockGitModule -ModuleName 'Get-UpstreamBranch' -gitCli "fetch $($config.remote) $($config.upstreamBranch)"
    }
}

Export-ModuleMember -Function Initialize-FetchUpstreamBranch
