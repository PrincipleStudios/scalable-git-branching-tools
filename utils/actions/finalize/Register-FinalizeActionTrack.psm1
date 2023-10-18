Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function Register-FinalizeActionTrack([PSObject] $finalizeActions) {
    $finalizeActions['track'] = {
        param(
            [Parameter()][AllowEmptyCollection()][string[]] $branches,
            [Parameter()][bool] $createIfNotTracked,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )
        [string[]] $tracked = @()
        $config = Get-Configuration
        if ($null -eq $config.remote) {
            return $tracked
        }

        $currentBranch = Get-CurrentBranch
        foreach ($branch in $branches) {
            $localBranch = Get-LocalBranchForRemote $branch
            if (-not $localBranch -AND $currentBranch -eq $branch) {
                # current branch matches tracked one, but doesn't currently track the remote
                $localBranch = $currentBranch
                Invoke-ProcessLogs "git branch $localBranch --set-upstream-to refs/remotes/$($config.remote)/$branch" {
                    git branch $localBranch --set-upstream-to "refs/remotes/$($config.remote)/$branch"
                }
            }
            
            if ($currentBranch -eq $localBranch) {
                # update head
                Invoke-ProcessLogs "git reset --hard refs/remotes/$($config.remote)/$branch" {
                    git reset --hard "refs/remotes/$($config.remote)/$branch"
                }
            } elseif ($localBranch -OR $createIfNotTracked) {
                $localBranch = $localBranch ? $localBranch : $branch
                # update
                Invoke-ProcessLogs "git branch $localBranch refs/remotes/$($config.remote)/$branch -f" {
                    git branch $localBranch "refs/remotes/$($config.remote)/$branch" -f
                }
            } else {
                continue
            }
            $tracked += $branch
        }

        return $tracked
    }
}

Export-ModuleMember -Function Register-FinalizeActionTrack
