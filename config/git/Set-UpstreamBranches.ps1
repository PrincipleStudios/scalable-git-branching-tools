. $PSScriptRoot/Get-UpstreamBranch.ps1
. $PSScriptRoot/Set-GitFiles.ps1
. $PSScriptRoot/Update-UpstreamBranch.ps1

function Set-UpstreamBranches(
    [Parameter(Mandatory)]$branchName, 
    [Parameter(Mandatory)][string[]]$upstreamBranches, 
    [Parameter(Mandatory)][Alias('m')][Alias('message')][String]$commitMessage,
    [Parameter(Mandatory)][PSObject] $config
) {
    $upstreamBranch = Get-UpstreamBranch $config -fetch
    $commitish = Set-GitFiles @{ $branchName = ($upstreamBranches -join "`n") } -m $commitMessage -branchName $upstreamBranch -dryRun
    if ($commitish -eq $nil -OR $commitish -eq '') {
        throw "Failed to create commit"
    }
    Update-UpstreamBranch $commitish $config
}
