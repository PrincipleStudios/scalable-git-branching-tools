Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

function Get-LocalBranchForRemote(
    [Parameter(Mandatory)][String] $branchName
) {
    $config = Get-Configuration
    if ($config.remote -ne $nil) {
        # Gets the local version of the remote tracking branch:
        $localBranch = Invoke-ProcessLogs "get local branch for $($config.remote)/$branchName" {
            git for-each-ref "--format=%(if:equals=$($config.remote)/$branchName)%(upstream:short)%(then)%(refname:short)%(else)%(end)" refs/heads --omit-empty
        } -allowSuccessOutput

        return $localBranch
    } else {
        return $branchName
    }
}

Export-ModuleMember -Function Get-LocalBranchForRemote
