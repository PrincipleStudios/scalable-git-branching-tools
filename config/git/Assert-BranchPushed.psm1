Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"

function Assert-BranchPushed([Parameter(Mandatory)][String] $branchName, [Switch] $failIfNoBranch, [Switch] $failIfNoUpstream, [Parameter()][String][Alias('m')] $message) {
    $config = Get-Configuration
    if ($config.remote -ne $nil) {
        # Ensure the branch exists locally
        git show-ref --verify --quiet refs/heads/$branchName
        if ($Global:LASTEXITCODE -ne 0) {
            if ($failIfNoBranch) {
                throw "Branch $branchName does not exist locally. $message"
            } else {
                return
            }
        }

        # Get the diff with the remote branch
        $remoteBranch = git rev-parse --abbrev-ref --symbolic-full-name "$($branchName)@{u}" 2> $nil
        if ($remoteBranch -ne $nil) {
            $diff = git rev-list --count ^$remoteBranch $branchName # Number of commits in branch excluding those already pushed
            if ($diff -ne 0) {
                throw "Branch $branchName has changes not pushed to $remoteBranch. $message"
            }
        } elseif ($failIfNoUpstream) {
            throw "Branch $branchName does not have a remote tracking branch. $message"
        }
    }
}

Export-ModuleMember -Function Assert-BranchPushed
