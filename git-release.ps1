#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][String] $sourceBranch,
    [Parameter(Mandatory)][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [Parameter()][String[]] $preserve,
    [switch] $dryRun,
    [switch] $cleanupOnly
)

. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/core/ArrayToHash.ps1
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-GitFileNames.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.psm1"

$config = Get-Configuration

Update-Git

if ($cleanupOnly) {
    # Verify that $target already has all of $sourceBranch
    $count = git rev-list ($config.remote -eq $nil ? $sourceBranch : "$($config.remote)/$($sourceBranch)") "^$($config.remote -eq $nil ? $target : "$($config.remote)/$($target)")" --count
    if ($count -ne 0) {
        throw "Found $count commits in $sourceBranch that were not included in $target"
    }
} else {
    $count = git rev-list ($config.remote -eq $nil ? $target : "$($config.remote)/$($target)") "^$($config.remote -eq $nil ? $sourceBranch : "$($config.remote)/$($sourceBranch)")" --count
    if ($count -ne 0) {
        throw "Could not fast-forward $target to $sourceBranch; $count commits in $target that were not included in $sourceBranch"
    }
}

$allPreserve = [String[]](@($target, $preserve) | ForEach-Object { $_ } | Select-Object -uniq)

$allUpstream = Select-UpstreamBranches $sourceBranch -recurse

$upstreamCache = @($allUpstream, $allPreserve) | ForEach-Object { $_ } | ArrayToHash -getValue { Select-UpstreamBranches $_ -recurse }

$preservedUpstream = [String[]]($allPreserve
    | ForEach-Object { $_; $upstreamCache[$_] }
    | ForEach-Object { $_ }
    | Select-Object -uniq)

$toRemove = @($allUpstream, $sourceBranch) | ForEach-Object { $_ } | Select-Object -uniq | Where-Object { $preservedUpstream -notcontains $_ }

function Invoke-RemoveBranches($branch) {
    if ($toRemove -contains $branch) {
        return $upstreamCache[$branch] | ForEach-Object { Invoke-RemoveBranches $_ } | Foreach-Object { $_ } | Select-Object -uniq
    }
    return $branch
}

$updates = Get-GitFileNames -branchName $config.upstreamBranch -remote $config.remote | ForEach-Object {
    if ($toRemove -contains $_) { return $nil }
    $upstream = Select-UpstreamBranches $_
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
        Write-Host "Would push $sourceBranch to $target"
    }
    Write-Host "Would remove $toRemove"
    Write-Host "Would perform updates: $(ConvertTo-Json $updates)"
} else {
    $commitMessage = "Release $sourceBranch to $target$($comment -eq $nil -or $comment -eq '' ? '' : "`n`n$comment")"
    $upstreamContents = $updates | ArrayToHash -getKey { $_.branch } -getValue { $_.newUpstream }
    $upstreamContents[$sourceBranch] = $nil
    $toRemove | ForEach-Object {
        $upstreamContents[$_] = $nil
    }
    $commitish = Set-MultipleUpstreamBranches $upstreamContents -m $commitMessage

    if ($config.remote -ne $nil) {
        $gitDeletions = [String[]]($toRemove | ForEach-Object { ":$_" })

        $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
        $releasePart = $cleanupOnly ? @() : @("$($config.remote)/$($sourceBranch):$target")

        git push @atomicPart $config.remote @releasePart @gitDeletions "$($commitish):refs/heads/$($config.upstreamBranch)"
    } else {
        git branch -f $config.upstreamBranch $commitish
        if (-not $cleanupOnly) {
            git branch -f $sourceBranch $target
        }
        $toRemove | ForEach-Object {
            git branch -D $_
        }
    }
}
