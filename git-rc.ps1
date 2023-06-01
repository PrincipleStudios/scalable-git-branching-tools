#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $branchName,
    [Parameter()][String[]] $branches,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $force
)

# git doesn't pass them as separate items in the array
. $PSScriptRoot/config/core/split-string.ps1
$branches = [String[]]($branches -eq $nil ? @() : (Split-String $branches))

. $PSScriptRoot/config/core/coalesce.ps1
. $PSScriptRoot/config/branch-utils/ConvertTo-BranchName.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-Branches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CreateBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-CheckoutBranch.psm1";
Import-Module -Scope Local "$PSScriptRoot/config/git/Invoke-MergeBranches.psm1";
Import-Module -Scope Local "$PSScriptRoot/config/git/Set-MultipleUpstreamBranches.psm1"

$config = Get-Configuration
Update-Git

Assert-CleanWorkingDirectory
$allBranches = Select-Branches
$selectedBranches = [PSObject[]]($allBranches | Where-Object {
        if ($branches -ne $nil -AND $branches -contains $_.branch) { return $true }
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

    Invoke-CreateBranch $branchName $upstreamBranches[0]
    Invoke-CheckoutBranch $branchName
    # TODO: do we need to reassert clean here?
    # Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
    $(Invoke-MergeBranches ($upstreamBranches | select -skip 1)).ThrowIfInvalid()

    $commitMessage = Coalesce $commitMessage "Add branch $branchName$($comment -eq $nil ? '' : " for $comment")"

    $upstreamCommitish = Set-MultipleUpstreamBranches -upstreamBanchesByBranchName @{ $branchName = $upstreamBranchesNoRemote } -m $commitMessage

    if ($config.remote -ne $nil) {
        $forcePart = $force ? @('--force') : @()
        $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
        git push $config.remote "$($branchName):refs/heads/$($branchName)" "$($upstreamCommitish):refs/heads/$($config.upstreamBranch)" @forcePart @atomicPart
        if ($global:LASTEXITCODE -ne 0) {
            throw "Unable to push $branchName to $($config.remote)"
        }
    }  else {
        git branch -f $config.upstreamBranch $upstreamCommitish
    }
} -cleanup {
    if ($config.remote -ne $nil) {
        git branch -D $branchName 2> $nil
    }
}
