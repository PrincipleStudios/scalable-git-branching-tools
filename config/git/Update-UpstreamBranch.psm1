Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"

function Update-UpstreamBranch(
    [Parameter(Mandatory)][string] $commitish,
    $config
) {
    if ($config -ne $nil) {
        throw 'config should no longer be provided'
    }
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
