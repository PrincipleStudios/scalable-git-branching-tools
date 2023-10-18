Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionTrack.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Register-FinalizeActionTrack' @PSBoundParameters
}

function Initialize-FinalizeActionTrackSuccess(
    [Parameter()][AllowEmptyCollection()][string[]] $branches,
    [Parameter()][AllowEmptyCollection()][string[]] $untracked,
    [Parameter()][string] $currentBranch
) {
    $config = Get-Configuration

    if ($currentBranch) {
        Initialize-CurrentBranch $currentBranch
    } else {
        Initialize-NoCurrentBranch
    }

    foreach ($branch in $untracked) {
        Initialize-GetLocalBranchForRemote $branch $null
    }

    foreach ($branch in $branches) {
        if ($untracked -notcontains $branch) {
            Initialize-GetLocalBranchForRemote $branch $branch
        }

        if ($branch -eq $currentBranch) {
            if ($untracked -contains $currentBranch) {
                Invoke-MockGit "branch $currentBranch --set-upstream-to refs/remotes/$($config.remote)/$currentBranch"
            }
            Invoke-MockGit "reset --hard refs/remotes/$($config.remote)/$branch"
        } else {
            Invoke-MockGit "branch $branch refs/remotes/$($config.remote)/$branch -f"
        }
    }
}

Export-ModuleMember -Function Initialize-FinalizeActionTrackSuccess
