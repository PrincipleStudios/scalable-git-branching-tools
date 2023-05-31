#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory)][string] $branchName,
    [Parameter()][String[]] $branches,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [switch] $force,
    [Switch] $noFetch
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
. $PSScriptRoot/config/git/Set-UpstreamBranches.ps1

$config = Get-Configuration

if (-not $noFetch) {
    Update-Git
}

$tickets = $tickets | Where-Object { $_ -ne '' -AND $_ -ne $nil }

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

    Set-UpstreamBranches $branchName $upstreamBranchesNoRemote -m $commitMessage -config $config

    if ($config.remote -ne $nil) {
        $params = $force ? @('--force') : @()
        git push $config.remote "$($branchName):refs/heads/$($branchName)" @params
        if ($global:LASTEXITCODE -ne 0) {
            throw "Unable to push $branchName to $($config.remote)"
        }
    }
} -cleanup {
    if ($config.remote -ne $nil) {
        git branch -D $branchName 2> $nil
    }
}
