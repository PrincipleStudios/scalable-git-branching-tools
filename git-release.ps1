#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter(Mandatory)][String] $target,
    [Parameter][String[]] $preserve,
    [switch] $dryRun
)

. $PSScriptRoot/config/core/ArrayToHash.ps1
. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
. $PSScriptRoot/config/git/Get-GitFileNames.ps1
. $PSScriptRoot/config/git/Set-MultipleUpstreamBranches.ps1

$config = Get-Configuration

if (-not $noFetch) {
    Update-Git -config $config
}

$allPreserve = [String[]](@($target, $preserve) | ForEach-Object { $_ } | Select-Object -uniq)

$allUpstream = Select-UpstreamBranches $branchName -config $config -recurse

$upstreamCache = @($allUpstream, $allPreserve) | ForEach-Object { $_ } | ArrayToHash -getValue { Select-UpstreamBranches $_ -config $config -recurse }

$preservedUpstream = [String[]]($allPreserve 
    | ForEach-Object { $_; $upstreamCache[$_] }
    | ForEach-Object { $_ }
    | Select-Object -uniq)

$toRemove = @($allUpstream, $branchName) | ForEach-Object { $_ } | Select-Object -uniq | Where-Object { $preservedUpstream -notcontains $_ }

function Invoke-RemoveBranches($branch) {
    if ($toRemove -contains $branch) {
        return $upstreamCache[$branch] | ForEach-Object { Invoke-RemoveBranches $_ } | Foreach-Object { $_ } | Select-Object -uniq
    }
    return $branch
}

$updates = Get-GitFileNames -branchName $config.upstreamBranch -remote $config.remote | ForEach-Object {
    if ($toRemove -contains $_) { return $nil }
    $upstream = Select-UpstreamBranches $_ -config $config
    if (($upstream | Where-Object { $toRemove -contains $_ })) {
        # Needs to change
        return @{
            branch = $_
            newUpstream = [string[]]($upstream | ForEach-Object { Invoke-RemoveBranches $_ } | ForEach-Object { $_ } | Select-Object -uniq)
        }
    }
    return $nil
} | Where-Object { $_ -ne $nil }

# Write-Host (ConvertTo-Json @{ allUpstream = $allUpstream; allPreserve = $allPreserve; preservedUpstream = $preservedUpstream; toRemove = $toRemove; updates = $updates })

Write-Host "Would push $branchName to $target"
Write-Host "Would remove $toRemove"
Write-Host "Would perform updates: $(ConvertTo-Json $updates)"
