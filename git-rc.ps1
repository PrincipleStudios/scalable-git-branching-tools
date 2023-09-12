#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $target,
    [Parameter()][Alias('u')][Alias('upstream')][Alias('upstreams')][String[]] $upstreamBranches,
    [Parameter()][Alias('message')][Alias('m')][string] $comment,
    [switch] $force
)

# git doesn't pass them as separate items in the array
. $PSScriptRoot/config/core/split-string.ps1
$upstreamBranches = [String[]]($upstreamBranches -eq $nil ? @() : (Split-String $upstreamBranches))

. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/branch-utils/ConvertTo-BranchName.ps1
Import-Module -Scope Local "$PSScriptRoot/utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-Branches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.psm1";
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1";
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.psm1"

$config = Get-Configuration
Update-GitRemote

Assert-CleanWorkingDirectory
$allBranches = Select-Branches
$selectedBranches = [PSObject[]]($allBranches | Where-Object {
        if ($upstreamBranches -ne $nil -AND $upstreamBranches -contains $_.branch) { return $true }
        return $false
    })

$upstreamBranchesNoRemote = [string[]]($selectedBranches | Foreach-Object { ConvertTo-BranchName $_ })
$upstreamBranchesNoRemote = Compress-UpstreamBranches $upstreamBranchesNoRemote

if ($config.remote -ne $nil) {
    $upstreamBranches = [string[]]$upstreamBranchesNoRemote | Foreach-Object { "$($config.remote)/$_" }
} else {
    $upstreamBranches = $upstreamBranchesNoRemote
}

Invoke-PreserveBranch {

    Invoke-CreateBranch $target $upstreamBranches[0]
    Invoke-CheckoutBranch $target
    # TODO: do we need to reassert clean here?
    # Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
    $(Invoke-MergeBranches ($upstreamBranches | Select-Object -skip 1)).ThrowIfInvalid()

    $commitMessage = "Create branch $target$($comment -eq $nil -or $comment -eq '' ? '' : "`n`n$comment")"

    $upstreamCommitish = Set-MultipleUpstreamBranches -upstreamBanchesByBranchName @{ $target = $upstreamBranchesNoRemote } -m $commitMessage

    if ($config.remote -ne $nil) {
        $forcePart = $force ? @('--force') : @()
        $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
        git push $config.remote "$($target):refs/heads/$($target)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)" @forcePart @atomicPart
        if ($global:LASTEXITCODE -ne 0) {
            throw "Unable to push $target to $($config.remote)"
        }
    }  else {
        git branch -f $config.upstreamBranch $upstreamCommitish
    }
} -cleanup {
    if ($config.remote -ne $nil) {
        git branch -D $target 2> $nil
    }
}
