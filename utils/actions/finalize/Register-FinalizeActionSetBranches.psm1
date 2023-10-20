Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.psm1"

function ConvertTo-PushBranchList([Parameter(Mandatory)][Hashtable] $branches) {
    $result = $branches.Keys | Sort-Object | Foreach-Object {
        "$($branches[$_]):refs/heads/$($_)"
    }
    return $result
}

# Not to be re-exported; used for testing
Export-ModuleMember -Function ConvertTo-PushBranchList

function Register-FinalizeActionSetBranches([PSObject] $finalizeActions) {
    $finalizeActions['set-branches'] = {
        param(
            [Parameter()] $branches,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
            [switch] $dryRun
        )

        $branches = ConvertTo-Hashtable $branches
        $config = Get-Configuration

        $branches.Keys | Assert-ValidBranchName -diagnostics $diagnostics

        if ($null -ne $config.remote) {
            $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
            $branchList = ConvertTo-PushBranchList $branches
            if ($dryRun) {
                "git push $($config.remote) $atomicPart $branchList"
                return
            }
            Invoke-ProcessLogs "git push $($config.remote)" {
                git push $config.remote @atomicPart @branchList
            }
            if ($global:LASTEXITCODE -ne 0) {
                Add-ErrorDiagnostic $diagnostics "Unable to push updates to $($config.remote)"
            }
        } else {
            $currentBranch = Get-CurrentBranch

            foreach ($key in $branches.Keys) {
                if ($currentBranch -eq $key) {
                    # update head, since it matches the branch to be "pushed"
                    if ($dryRun) {
                        "git reset --hard `"$($branches[$key])`""
                        continue
                    }
                    Invoke-ProcessLogs "git reset --hard $($branches[$key])" {
                        git reset --hard "$($branches[$key])"
                    }
                } else {
                    # just update the branch
                    if ($dryRun) {
                        "git branch $key `"$($branches[$key])`" -f"
                        continue
                    }
                    Invoke-ProcessLogs "git branch $key $($branches[$key])" {
                        git branch $key "$($branches[$key])" -f
                    }
                }
                if ($global:LASTEXITCODE -ne 0) {
                    Add-ErrorDiagnostic $diagnostics "Unable to update local branches"
                }
            }
        }
    }
}

Export-ModuleMember -Function Register-FinalizeActionSetBranches
