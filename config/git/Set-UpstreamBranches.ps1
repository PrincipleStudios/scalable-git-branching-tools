. $PSScriptRoot/Get-Configuration.ps1
. $PSScriptRoot/Set-GitFiles.ps1

function Set-UpstreamBranches(
    [Parameter(Mandatory)]$branchName, 
    [Parameter(Mandatory)][string[]]$upstreamBranches, 
    [Parameter(Mandatory)][Alias('m')][Alias('message')][String]$commitMessage
) {
    $config = Get-Configuration

    $upstreamBranch = $config.remote -eq $nil ? $config.upstreamBranch : "$($config.remote)/$($config.upstreamBranch)"

    if ($config.remote -ne $nil) {
        git fetch $config.remote $config.upstreamBranch 2> $nil
    }
    $commitish = Set-GitFiles @{ $branchName = ($upstreamBranches -join "`n") } -m $commitMessage -branchName $upstreamBranch -dryRun
    if ($commitish -eq $nil -OR $commitish -eq '') {
        throw "Failed to create commit"
    }
    if ($config.remote -ne $nil) {
        git push $config.remote "$($commitish):refs/heads/$($config.upstreamBranch)"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update remote branch $upstreamBranch; another dev must have been updating it. Try again later."
        }
    }
}
