. $PSScriptRoot/Set-MultipleUpstreamBranches.ps1

function Set-UpstreamBranches(
    [Parameter(Mandatory)]$branchName, 
    [Parameter(Mandatory)][string[]]$upstreamBranches, 
    [Parameter(Mandatory)][Alias('m')][Alias('message')][String]$commitMessage,
    [Parameter(Mandatory)][PSObject] $config
) {
    Set-MultipleUpstreamBranches -upstreamBanchesByBranchName @{ $branchName = $upstreamBranches } -m $commitMessage -config $config
}
