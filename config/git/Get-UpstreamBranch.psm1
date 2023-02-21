Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"

function Get-UpstreamBranch(
    [switch] $fetch
) {
    $config = Get-Configuration
    $upstreamBranch = $config.remote -eq $nil ? $config.upstreamBranch : "$($config.remote)/$($config.upstreamBranch)"

    if ($config.remote -ne $nil -AND $fetch) {
        git fetch $config.remote $config.upstreamBranch 2> $nil
    }

    return $upstreamBranch
}
Export-ModuleMember -Function Get-UpstreamBranch
