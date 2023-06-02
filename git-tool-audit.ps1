#!/usr/bin/env pwsh

Param(
	[Switch] $prune,
	[Switch] $simplify,
    [Switch] $all
)

if ($all) {
    $prune = $true
    $simplify = $true
}

. $PSScriptRoot/config/branch-utils/ConvertTo-BranchName.ps1
. $PSScriptRoot/config/core/ArrayToHash.ps1
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Update-Git.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-Branches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Get-GitFileNames.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/config/git/Compress-UpstreamBranches.psm1"

$config = Get-Configuration
Update-Git -prune
Write-Host 'Finished ''git fetch origin'''

$allRemoteBranches = Select-Branches | Foreach-Object { ConvertTo-BranchName $_ }
$allConfiguredBranches = Get-GitFileNames -branchName $config.upstreamBranch -remote $config.remote
$allConfiguredUpstream = $allConfiguredBranches | ArrayToHash -getValue { Select-UpstreamBranches $_ }

$setUpstream = $false

# simplify
$updatedConfigurations = [System.Collections.ArrayList]@()

$simplifyResult = $allConfiguredBranches
    | ArrayToHash -getValue {
        $result = Compress-UpstreamBranches $allConfiguredUpstream[$_]
        if (($result -join ',') -ne ($allConfiguredUpstream[$_] -join ',')) {
            $updatedConfigurations.Add($_) > $null
        }
        return $result
    }

if ($updatedConfigurations.Count -ne 0) {
    Write-Host -ForegroundColor green "Simplify check discovered the following:"
    Write-Host -ForegroundColor green "  Configured branches can be simplified:"
    foreach ($branch in $updatedConfigurations) {
        Write-Host -ForegroundColor green "  - $branch"
    }
    if ($simplify) {
        $allConfiguredUpstream = $simplifyResult
        $setUpstream = $true
    }
}

# prune
$removedConfigurations = [System.Collections.ArrayList]@()
$updatedConfigurations = @{}

$pruneResult = $allConfiguredBranches | Where-Object {
        $result = $allRemoteBranches -contains $_
        if (-not $result) { $removedConfigurations.Add($_) > $null }
        return $result
    }
    | ArrayToHash -getValue {
        $references = [System.Collections.ArrayList]@()
        $result = $allConfiguredUpstream[$_] | Where-Object {
            if ($_ -eq $nil) { return $true }
            $result = $allRemoteBranches -contains $_
            if (-not $result) { $references.Add($_) > $null }
            return $result
        }
        if ($references.Count -ne 0) {
            $updatedConfigurations[$_] = [string[]]$references
        }
        return $result
    }

if ($removedConfigurations.Count -ne 0 -OR $updatedConfigurations.Count -ne 0) {
    Write-Host -ForegroundColor green "Prune check discovered the following:"
    if ($removedConfigurations.Count -ne 0) {
        Write-Host -ForegroundColor green "  Configured branches that no longer exist:"
        foreach ($branch in $removedConfigurations) {
            Write-Host -ForegroundColor green "  - $branch"
        }
    }
    if ($updatedConfigurations.Count -ne 0) {
        Write-Host -ForegroundColor yellow "  Configured branches with upstream branches that no longer exist:"
        foreach ($branch in $updatedConfigurations.Keys) {
            Write-Host -ForegroundColor yellow "  - $branch`:"
            foreach ($oldChild in $updatedConfigurations[$branch]) {
                Write-Host -ForegroundColor yellow "    - $oldChild"
            }
        }
        Write-Host -ForegroundColor yellow "  Note: These branches may no longer reference the correct upstream if applied."
    }

    if ($prune) {
        $allConfiguredBranches = $pruneResult.Keys
        $allConfiguredUpstream = $pruneResult
        $setUpstream = $true
    }
}

# TODO - apply
Write-Host (ConvertTo-Json $allConfiguredUpstream)
