Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-BranchSyncState.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Get-BranchSyncState' @PSBoundParameters
}

function Initialize-RemoteBranchSyncState([String] $branchName, [AllowEmptyString()][AllowNull()][string] $state) {
    $remote = $(Get-Configuration).remote
    if ($null -eq $remote) { throw 'Do not initialize remote state if remote is not set' }
    $remoteBranch = "$remote/$branchName"

    Invoke-MockGit "for-each-ref --format=%(if:equals=$remoteBranch)%(upstream:short)%(then)%(upstream:trackshort)%(else)%(end) refs/heads --omit-empty" $state
}

function Initialize-RemoteBranchBehind([String] $branchName) {
    Initialize-RemoteBranchSyncState $branchName '<'
}

function Initialize-RemoteBranchAhead([String] $branchName) {
    Initialize-RemoteBranchSyncState $branchName '>'
}

function Initialize-RemoteBranchNotTracked([String] $branchName) {
    Initialize-RemoteBranchSyncState $branchName $null
}

function Initialize-RemoteBranchInSync([String] $branchName) {
    Initialize-RemoteBranchSyncState $branchName '='
}

function Initialize-RemoteBranchAheadAndBehind([String] $branchName) {
    Initialize-RemoteBranchSyncState $branchName '<>'
}

Export-ModuleMember -Function Initialize-RemoteBranchBehind, Initialize-RemoteBranchAhead, Initialize-RemoteBranchNotTracked, Initialize-RemoteBranchInSync, Initialize-RemoteBranchAheadAndBehind
