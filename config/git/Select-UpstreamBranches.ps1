. $PSScriptRoot/Get-Configuration.ps1
. $PSScriptRoot/Get-GitFile.ps1

function Select-UpstreamBranches([String]$branchName, [switch] $includeRemote) {
    $config = Get-Configuration
    $parentBranches = Get-GitFile $branchName "$($config.remote)/$($config.upstreamBranch)"
    if ($includeRemote) {
        return $parentBranches | ForEach-Object { "$($config.remote)/$_" }
    } else {
        return $parentBranches
    }
}
