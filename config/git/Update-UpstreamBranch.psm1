Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"

function Update-UpstreamBranch(
    [Parameter(Mandatory)][string] $commitish
) {
    $config = Get-Configuration
    if ($config.remote -ne $nil) {
        git push $config.remote "$($commitish):refs/heads/$($config.upstreamBranch)"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update remote branch $($config.remote)/$($config.upstreamBranch); another dev must have been updating it. Try again later."
        }
    } else {
        git branch "$($config.upstreamBranch)" $commitish -f
    }
}
Export-ModuleMember -Function Update-UpstreamBranch
