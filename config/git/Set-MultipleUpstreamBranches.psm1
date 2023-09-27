Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../utils/git.psm1"
. $PSScriptRoot/../core/ArrayToHash.ps1

function Set-MultipleUpstreamBranches(
    [Parameter(Mandatory)][PSObject]$upstreamBanchesByBranchName,
    [Parameter(Mandatory)][Alias('m')][Alias('message')][String]$commitMessage
) {
    $upstreamBranch = Get-UpstreamBranch -fetch
    $contents = $upstreamBanchesByBranchName.Keys | ArrayToHash -getValue { $upstreamBanchesByBranchName[$_] -eq $nil ? $nil : "$($upstreamBanchesByBranchName[$_] -join "`n")`n" }
    $commitish = Set-GitFiles $contents -m $commitMessage -branchName $upstreamBranch
    if ($commitish -eq $nil -OR $commitish -eq '') {
        throw "Failed to create commit"
    }
    return $commitish
}
Export-ModuleMember -Function Set-MultipleUpstreamBranches
