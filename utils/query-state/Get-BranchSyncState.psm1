Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

function Get-BranchSyncState(
    [Parameter(Mandatory)][String] $branchName
) {
    $config = Get-Configuration
    if ($config.remote -ne $nil) {
        # Will give empty string for not tracked, `<` for behind, `>` for commits that aren't pushed, `=` for same, and `<>` for both remote and local have extra commits
        $syncState = Invoke-ProcessLogs "get sync state for $($config.remote)/$branchName" {
            git for-each-ref "--format=%(if:equals=$($config.remote)/$branchName)%(upstream:short)%(then)%(upstream:trackshort)%(else)%(end)" refs/heads --omit-empty
        } -allowSuccessOutput

        return $syncState
    } else {
        return '='
    }
}

Export-ModuleMember -Function Get-BranchSyncState
