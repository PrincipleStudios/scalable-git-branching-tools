#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $remote,
    [Parameter()][String] $upstreamBranch,
    [Parameter()][String] $defaultServiceLine,
	[Switch] $enableAtomicPush,
	[Switch] $disableAtomicPush
)

. $PSScriptRoot/config/git/Get-Configuration.ps1

$oldConfig = Get-Configuration

if ($remote -ne '') {
    if ((git remote) -notcontains $remote) {
        throw "$remote not a valid remote for the repo."
    } else {
        git config scaled-git.remote $remote
    }
    Write-Host "Set remote: $remote"
} else {
    $remote = $oldConfig.remote
    Write-Host "Using previous remote: $remote"
}

if ($upstreamBranch -ne '') {
    git config scaled-git.upstreamBranch $upstreamBranch
    Write-Host "Set upstream: $upstreamBranch"
} else {
    Write-Host "Using previous upstream: $($oldConfig.upstreamBranch)"
}

if ($defaultServiceLine -ne '') {
    $expected = $remote -eq $nil ? $defaultServiceLine : "$remote/$defaultServiceLine"
    $branches = $remote -eq $nil ? (git branch --format '%(refname:short)') : (git branch -r --format '%(refname:short)')
    if ($branches -notcontains $expected) {
        throw "$expected is not found"
    }
    git config scaled-git.defaultServiceLine $defaultServiceLine
    Write-Host "Set default service line: $defaultServiceLine"
} else {
    Write-Host "Using previous default service line: $($oldConfig.defaultServiceLine)"
}

if ($enableAtomicPush) {
	git config scaled-git.atomicPushEnabled true
	Write-Host "Enabling atomic push"
}

if ($disableAtomicPush) {
	git config scaled-git.atomicPushEnabled false
	Write-Host "Disabling atomic push"
}
