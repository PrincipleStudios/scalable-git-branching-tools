Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
. $PSScriptRoot/Set-GitFiles.ps1
. $PSScriptRoot/Update-UpstreamBranch.ps1
. $PSScriptRoot/../core/ArrayToHash.ps1

function Set-MultipleUpstreamBranches(
    [Parameter(Mandatory)][PSObject]$upstreamBanchesByBranchName,
    [Parameter(Mandatory)][Alias('m')][Alias('message')][String]$commitMessage,
    [Parameter(Mandatory)][PSObject] $config
) {
    $upstreamBranch = Get-UpstreamBranch -fetch
    $contents = $upstreamBanchesByBranchName.Keys | ArrayToHash -getValue { $upstreamBanchesByBranchName[$_] -join "`n" }
    $commitish = Set-GitFiles $contents -m $commitMessage -branchName $upstreamBranch -dryRun
    if ($commitish -eq $nil -OR $commitish -eq '') {
        throw "Failed to create commit"
    }
    Update-UpstreamBranch $commitish $config
}
