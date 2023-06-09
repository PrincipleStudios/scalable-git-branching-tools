. $PSScriptRoot/../branch-utils/ConvertTo-BranchName.ps1
. $PSScriptRoot/../core/ArrayToHash.ps1
Import-Module -Scope Local "$PSScriptRoot/../git/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Select-Branches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Get-GitFileNames.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Set-MultipleUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Update-UpstreamBranch.psm1"

function Invoke-PruneAudit([switch] $apply) {
    $config = Get-Configuration

    $allRemoteBranches = Select-Branches | Foreach-Object { ConvertTo-BranchName $_ }
    $allConfiguredUpstream = Get-GitFileNames -branchName $config.upstreamBranch -remote $config.remote
        | ArrayToHash -getValue { Select-UpstreamBranches $_ }

    $updatedConfigurations = @{}
    $changedConfigurations = @{}

    $pruneResult = $allConfiguredUpstream.Keys
        | ArrayToHash -getValue {
            if ($allRemoteBranches -notcontains $_) {
                $updatedConfigurations[$_] = $null
                return $null
            }
            $references = [System.Collections.ArrayList]@()
            $result = $allConfiguredUpstream[$_] | Where-Object {
                if ($_ -eq $nil) { return $true }
                $result = $allRemoteBranches -contains $_
                if (-not $result) { $references.Add($_) > $null }
                return $result
            }
            if ($references.Count -ne 0) {
                $changedConfigurations[$_] = [string[]]$references
                $updatedConfigurations[$_] = $result
            }
            return $result
        }

    if ($updatedConfigurations.Keys.Count -ne 0) {
        Write-Host -ForegroundColor green "Prune check discovered the following:"
        $removed = $updatedConfigurations.Keys | Where-Object { $updatedConfigurations[$_] -eq $nil }
        $updated = $updatedConfigurations.Keys | Where-Object { $updatedConfigurations[$_] -ne $nil }
        if ($removed.Count -ne 0) {
            Write-Host -ForegroundColor green "  Configured branches that no longer exist:"
            foreach ($branch in $removed) {
                Write-Host -ForegroundColor green "  - $branch"
            }
        }
        if ($changedConfigurations.Count -ne 0) {
            Write-Host -ForegroundColor yellow "  Configured branches with upstream branches that no longer exist:"
            foreach ($branch in $changedConfigurations.Keys) {
                Write-Host -ForegroundColor yellow "  - $branch`:"
                Write-Host -ForegroundColor yellow "      Removing:"
                foreach ($oldChild in $changedConfigurations[$branch]) {
                    Write-Host -ForegroundColor yellow "      - $oldChild"
                }
            }
            Write-Host -ForegroundColor yellow "  Note: These branches may no longer reference the correct upstream if applied."
        }

        if ($apply) {
            $commitish = Set-MultipleUpstreamBranches $updatedConfigurations -m "Applied changes from 'prune' audit"
            Update-UpstreamBranch $commitish
        }
    }
}

Export-ModuleMember -Function Invoke-PruneAudit
