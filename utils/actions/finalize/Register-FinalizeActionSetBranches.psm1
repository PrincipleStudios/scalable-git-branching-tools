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
            [Parameter()][AllowEmptyCollection()][string[]] $track,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $branches = ConvertTo-Hashtable $branches
        $config = Get-Configuration

        $branches.Keys | Assert-ValidBranchName -diagnostics $diagnostics

        if ($null -ne $config.remote) {
            $atomicPart = $config.atomicPushEnabled ? @("--atomic") : @()
            $branchList = ConvertTo-PushBranchList $branches
            Invoke-ProcessLogs "git push $($config.remote)" {
                git push $config.remote @atomicPart @branchList
            }
            if ($global:LASTEXITCODE -ne 0) {
                Add-ErrorDiagnostic $diagnostics "Unable to push updates to $($config.remote)"
            }
            

            foreach ($key in $track) {
                Invoke-ProcessLogs "git branch $key $($branches[$key])" {
                    git branch $key $($branches[$key]) -f
                }
                Invoke-ProcessLogs "git branch $key --set-upstream-to $($config.remote)/$key" {
                    git branch $key --set-upstream-to "$($config.remote)/$key"
                }
            }
        } else {
            foreach ($key in $branches.Keys) {
                Invoke-ProcessLogs "git branch $key $($branches[$key])" {
                    git branch $key $($branches[$key]) -f
                }
                if ($global:LASTEXITCODE -ne 0) {
                    Add-ErrorDiagnostic $diagnostics "Unable to update local branches"
                }
            }
        }
    }
}

Export-ModuleMember -Function Register-FinalizeActionSetBranches
