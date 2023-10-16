Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Get-LocalBranchForRemote' @PSBoundParameters
}

function Initialize-GetLocalBranchForRemote([string] $remoteBranch, [string][AllowNull()] $localBranch) {
    $remote = $(Get-Configuration).remote
    if ($null -eq $remote) { return }

    Invoke-MockGit "for-each-ref --format=%(if:equals=$remote/$remoteBranch)%(upstream:short)%(then)%(refname:short)%(else)%(end) refs/heads --omit-empty" -MockWith $localBranch
}

Export-ModuleMember -Function Initialize-GetLocalBranchForRemote
