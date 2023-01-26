#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter(Mandatory)][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [Parameter()][String[]] $preserve,
    [switch] $dryRun,
    [Switch] $noFetch,
    [switch] $cleanupOnly
)

. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/core/ArrayToHash.ps1
. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Select-UpstreamBranches.ps1
. $PSScriptRoot/config/git/Get-GitFileNames.ps1

$config = Get-Configuration

if (-not $noFetch) {
    Update-Git -config $config
}

if ($cleanupOnly) {
    # Verify that $target already has all of $branchName
    $count = git rev-list ($config.remote -eq $nil ? $branchName : "$($config.remote)/$($branchName)") "^$($config.remote -eq $nil ? $target : "$($config.remote)/$($target)")" --count
    if ($count -ne 0) {
        throw "Found $count commits in $branchName that were not included in $target"
    }
} else {
    $count = git rev-list ($config.remote -eq $nil ? $target : "$($config.remote)/$($target)") "^$($config.remote -eq $nil ? $branchName : "$($config.remote)/$($branchName)")" --count
    if ($count -ne 0) {
        throw "Could not fast-forward $target to $branchname; $count commits in $target that were not included in $branchname"
    }
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

if ($dryRun) {
    if (-not $cleanupOnly) {
        Write-Host "Would push $branchName to $target"
    }
    Write-Host "Would remove $toRemove"
    Write-Host "Would perform updates: $(ConvertTo-Json $updates)"
} else {
    $commitMessage = Coalesce $commitMessage "Release $branchName to $target"
    $upstreamContents = $updates | ArrayToHash -getKey { $_.branch } -getValue { $_.newUpstream -join "`n" }
    $upstreamContents[$branchName] = $nil
    $toRemove | ForEach-Object {
        $upstreamContents[$_] = $nil
    }

    $commitish = Set-GitFiles $upstreamContents -m $commitMessage -branchName $config.upstreamBranch -remote $config.remote -dryRun

    if ($config.remote -ne $nil) {
        $gitDeletions = $toRemove | ForEach-Object { ":$_" }

        $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
        $releasePart = $cleanupOnly ? @() : @("$($config.remote)/$($branchName):$target")

        git push @atomicPart $config.remote @releasePart @gitDeletions "$($commitish):refs/heads/$($config.upstreamBranch)"
    } else {
        git branch -f $config.upstreamBranch $commitish
        if (-not $cleanupOnly) {
            git branch -f $branchName $target
        }
        $toRemove | ForEach-Object {
            git branch -D $_
        }
    }
}
