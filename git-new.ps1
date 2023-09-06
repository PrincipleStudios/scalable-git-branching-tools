#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][String] $branchName,
    [Parameter()][Alias('m')][Alias('message')][ValidateLength(1,25)][String] $comment,
    [Parameter()][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches
)

Import-Module -Scope Local "$PSScriptRoot/utils/framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/utils/input.psm1"
$upstreamBranches = Expand-StringArray $upstreamBranches

$diagnostics = New-Diagnostics
Assert-ValidBranchName $branchName -diagnostics $diagnostics
$upstreamBranches | Assert-ValidBranchName -diagnostics $diagnostics
Assert-Diagnostics $diagnostics

Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-RemoteTracking.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Compress-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.psm1"

$config = Get-Configuration
Update-GitRemote
Assert-Diagnostics $diagnostics

if ($upstreamBranches -ne $nil -AND $upstreamBranches.length -gt 0) {
    $parentBranchesNoRemote = $upstreamBranches
} elseif ($config.defaultServiceLine -ne $nil) {
    $parentBranchesNoRemote = [string[]] @( $config.defaultServiceLine )
}
$parentBranchesNoRemote = Compress-UpstreamBranches $parentBranchesNoRemote

if ($parentBranchesNoRemote.Length -eq 0) {
    throw "No parents could be determined for new branch '$branchName'."
}

if ($config.remote -ne $nil) {
    $upstreamBranches = [string[]]$parentBranchesNoRemote | Foreach-Object { "$($config.remote)/$_" }
} else {
    $upstreamBranches = $parentBranchesNoRemote
}

Assert-CleanWorkingDirectory

$upstreamCommitish = Set-MultipleUpstreamBranches @{ $branchName = $parentBranchesNoRemote } -m "Add branch $branchName$($comment -eq $nil -OR $comment -eq '' ? '' : " for $comment")"

Invoke-PreserveBranch {
    Invoke-CreateBranch $branchName $upstreamBranches[0]
    Invoke-CheckoutBranch $branchName
    Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
    $(Invoke-MergeBranches ($upstreamBranches | Select-Object -skip 1)).ThrowIfInvalid()

    if ($config.remote -ne $nil) {
        $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
        git push $config.remote @atomicPart "$($branchName):refs/heads/$($branchName)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)"
        Set-RemoteTracking $branchName
    } else {
        git branch -f $config.upstreamBranch $upstreamCommitish --quiet
    }
} -cleanup {
    git branch -D $branchName 2> $nil
} -onlyIfError
