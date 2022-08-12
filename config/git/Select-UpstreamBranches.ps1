. $PSScriptRoot/Get-UpstreamBranch.ps1
. $PSScriptRoot/Get-GitFile.ps1

function Select-UpstreamBranches([String]$branchName, [switch] $includeRemote, [Parameter(Mandatory)][PSObject] $config) {
    $upstreamBranch = Get-UpstreamBranch $config
    $parentBranches = Get-GitFile $branchName $upstreamBranch
    if ($includeRemote) {
        return $parentBranches | ForEach-Object { $config.remote -eq $nil ? $_ : "$($config.remote)/$_" }
    } else {
        return $parentBranches
    }
}
