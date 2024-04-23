#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][Alias('sourceBranch')][String] $source,
    [Parameter(Mandatory)][Alias('targetBranch')][String] $target,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [Parameter()][String[]] $preserve,
    [switch] $cleanupOnly,
    [switch] $noFetch,
    [switch] $quiet,
    [switch] $dryRun
)

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/actions.psm1"

$diagnostics = New-Diagnostics
if (-not $noFetch) {
    Update-GitRemote -quiet:$quiet
}

$commonParams = @{
    diagnostics = $diagnostics
}

# Assert up-to-date
# a) if $cleanupOnly, ensure no commits are in source that are not in target
# b) otherwise, ensure no commits are in target that are not in source
Invoke-LocalAction @commonParams @{
    type = 'assert-updated'
    parameters = $cleanupOnly `
        ? @{ downstream = $target; upstream = $source }
        : @{ downstream = $source; upstream = $target }
}
Assert-Diagnostics $diagnostics

# $toRemove = (git show-upstream $source -recurse) without ($target, git show-upstream $target -recurse)
$sourceUpstream = Invoke-LocalAction @commonParams @{
    type = 'get-upstream'
    parameters = @{ target = $source; recurse = $true }
}
Assert-Diagnostics $diagnostics

$targetUpstream = Invoke-LocalAction @commonParams @{
    type = 'get-upstream'
    parameters = @{ target = $target; recurse = $true }
}
Assert-Diagnostics $diagnostics

$keep = @($target) + $targetUpstream
[string[]]$toRemove = (@($source) + $sourceUpstream) | Where-Object { $_ -notin $keep }

# For all branches:
#    1. Replace $toRemove branches with $target
#    2. Simplify (new)

$originalUpstreams = Invoke-LocalAction @commonParams @{
    type = 'get-all-upstreams'
    parameters= @{}
}
Assert-Diagnostics $diagnostics

$resultUpstreams = @{}
foreach ($branch in $originalUpstreams.Keys) {
    if ($branch -in $toRemove) {
        $resultUpstreams[$branch] = $null
        continue
    }
    
    if ($originalUpstreams[$branch] | Where-Object { $_ -in $toRemove }) {
        $resultUpstreams = Invoke-LocalAction @commonParams @{
            type = 'filter-branches'
            parameters = @{
                include = @($target) + $originalUpstreams[$branch]
                exclude = $toRemove
            }
        }
    }
}

Write-Host (ConvertTo-Json $resultUpstreams)


# Finalize:
#    1. Push the following:
#        - Delete $toRemove branches
#        - Update _upstream
#        - If not $cleanupOnly, push $source commitish to $target

# if ($cleanupOnly) {
#     # Verify that $target already has all of $sourceBranch
#     $count = git rev-list ($config.remote -eq $nil ? $sourceBranch : "$($config.remote)/$($sourceBranch)") "^$($config.remote -eq $nil ? $target : "$($config.remote)/$($target)")" --count
#     if ($count -ne 0) {
#         throw "Found $count commits in $sourceBranch that were not included in $target"
#     }
# } else {
#     $count = git rev-list ($config.remote -eq $nil ? $target : "$($config.remote)/$($target)") "^$($config.remote -eq $nil ? $sourceBranch : "$($config.remote)/$($sourceBranch)")" --count
#     if ($count -ne 0) {
#         throw "Could not fast-forward $target to $sourceBranch; $count commits in $target that were not included in $sourceBranch"
#     }
# }

# $allPreserve = [String[]](@($target, $preserve) | ForEach-Object { $_ } | Select-Object -uniq)

# $allUpstream = Select-UpstreamBranches $sourceBranch -recurse

# $upstreamCache = @($allUpstream, $allPreserve) | ForEach-Object { $_ } | ArrayToHash -getValue { Select-UpstreamBranches $_ -recurse }

# $preservedUpstream = [String[]]($allPreserve
#     | ForEach-Object { $_; $upstreamCache[$_] }
#     | ForEach-Object { $_ }
#     | Select-Object -uniq)

# $toRemove = @($allUpstream, $sourceBranch) | ForEach-Object { $_ } | Select-Object -uniq | Where-Object { $preservedUpstream -notcontains $_ }

# function Invoke-RemoveBranches($branch) {
#     if ($toRemove -contains $branch) {
#         return $upstreamCache[$branch] | ForEach-Object { Invoke-RemoveBranches $_ } | Foreach-Object { $_ } | Select-Object -uniq
#     }
#     return $branch
# }

# $updates = Get-GitFileNames -branchName $config.upstreamBranch -remote $config.remote | ForEach-Object {
#     if ($toRemove -contains $_) { return $nil }
#     $upstream = Select-UpstreamBranches $_
#     if (($upstream | Where-Object { $toRemove -contains $_ })) {
#         # Needs to change
#         return @{
#             branch = $_
#             newUpstream = [string[]]($upstream | ForEach-Object { Invoke-RemoveBranches $_ } | ForEach-Object { $_ } | Select-Object -uniq)
#         }
#     }
#     return $nil
# } | Where-Object { $_ -ne $nil }

# if ($dryRun) {
#     if (-not $cleanupOnly) {
#         Write-Host "Would push $sourceBranch to $target"
#     }
#     Write-Host "Would remove $toRemove"
#     Write-Host "Would perform updates: $(ConvertTo-Json $updates)"
# } else {
#     $commitMessage = "Release $sourceBranch to $target$($comment -eq $nil -or $comment -eq '' ? '' : "`n`n$comment")"
#     $upstreamContents = $updates | ArrayToHash -getKey { $_.branch } -getValue { $_.newUpstream }
#     $upstreamContents[$sourceBranch] = $nil
#     $toRemove | ForEach-Object {
#         $upstreamContents[$_] = $nil
#     }
#     $commitish = Set-MultipleUpstreamBranches $upstreamContents -m $commitMessage

#     if ($config.remote -ne $nil) {
#         $gitDeletions = [String[]]($toRemove | ForEach-Object { ":$_" })

#         $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
#         $releasePart = $cleanupOnly ? @() : @("$($config.remote)/$($sourceBranch):$target")

#         git push @atomicPart $config.remote @releasePart @gitDeletions "$($commitish):refs/heads/$($config.upstreamBranch)"
#     } else {
#         git branch -f $config.upstreamBranch $commitish
#         if (-not $cleanupOnly) {
#             git branch -f $sourceBranch $target
#         }
#         $toRemove | ForEach-Object {
#             git branch -D $_
#         }
#     }
# }
