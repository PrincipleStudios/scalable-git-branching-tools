
function Update-UpstreamBranch(
    [Parameter(Mandatory)][string] $commitish,
    [Parameter(Mandatory)][PSObject] $config
) {
    if ($config.remote -ne $nil) {
        git push $config.remote "$($commitish):refs/heads/$($config.upstreamBranch)"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update remote branch $($config.remote)/$($config.upstreamBranch); another dev must have been updating it. Try again later."
        }
    }
}
