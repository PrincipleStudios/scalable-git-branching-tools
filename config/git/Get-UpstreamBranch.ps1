
function Get-UpstreamBranch(
    [Parameter(Mandatory)][PSObject] $config, 
    [switch] $fetch
) {
    $upstreamBranch = $config.remote -eq $nil ? $config.upstreamBranch : "$($config.remote)/$($config.upstreamBranch)"

    if ($config.remote -ne $nil -AND $fetch) {
        git fetch $config.remote $config.upstreamBranch 2> $nil
    }

    return $upstreamBranch
}
