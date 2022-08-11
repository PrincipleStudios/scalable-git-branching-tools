#!/usr/bin/env pwsh

Param(
    [Parameter()][String[]] $tickets,
    [Parameter()][String[]] $branches,
    [Parameter()][Alias('message')][Alias('m')][string] $commitMessage,
    [Parameter(Mandatory)][string] $label,
    [switch] $force,
    [Switch] $noFetch
)

# git doesn't pass them as separate items in the array
. $PSScriptRoot/config/core/split-string.ps1
$tickets = [String[]]($tickets -eq $nil ? @() : (Split-String $tickets))
$branches = [String[]]($branches -eq $nil ? @() : (Split-String $branches))

. $PSScriptRoot/config/branch-utils/Invoke-TicketsToBranches.ps1
. $PSScriptRoot/config/branch-utils/ConvertTo-BranchName.ps1
. $PSScriptRoot/config/branch-utils/Format-BranchName.ps1
. $PSScriptRoot/config/git/Get-Configuration.ps1
. $PSScriptRoot/config/git/Update-Git.ps1
. $PSScriptRoot/config/git/Assert-CleanWorkingDirectory.ps1
. $PSScriptRoot/config/git/Select-Branches.ps1
. $PSScriptRoot/config/git/Invoke-PreserveBranch.ps1
. $PSScriptRoot/config/git/Invoke-CreateBranch.ps1
. $PSScriptRoot/config/git/Invoke-CheckoutBranch.ps1
. $PSScriptRoot/config/git/Invoke-MergeBranches.ps1
. $PSScriptRoot/config/git/Set-UpstreamBranches.ps1

$config = Get-Configuration

if (-not $noFetch) {
    Update-Git -config $config
}

$tickets = $tickets | Where-Object { $_ -ne '' -AND $_ -ne $nil }

Assert-CleanWorkingDirectory
$allBranches = Select-Branches -config $config
$selectedBranches = [PSObject[]](Invoke-TicketsToBranches -tickets $tickets -branches $branches -allBranchInfo $allBranches)

$upstreamBranches = [string[]]($selectedBranches | Foreach-Object { ConvertTo-BranchName $_ -includeRemote })
$upstreamBranchesNoRemote = [string[]]($selectedBranches | Foreach-Object { ConvertTo-BranchName $_ })

$branchName = Format-BranchName -type 'rc' -comment $label

Invoke-PreserveBranch {
    
    Invoke-CreateBranch $branchName $upstreamBranches[0]
    Invoke-CheckoutBranch $branchName
    # TODO: do we need to reassert clean here?
    # Assert-CleanWorkingDirectory # checkouts can change ignored files; reassert clean
    Invoke-MergeBranches ($upstreamBranches | select -skip 1)

    Set-UpstreamBranches $branchName $upstreamBranchesNoRemote -m "Add branch $branchName$($comment -eq $nil ? '' : " for $comment")" -config $config

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
