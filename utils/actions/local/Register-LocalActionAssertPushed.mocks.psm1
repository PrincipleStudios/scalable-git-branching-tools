Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionAssertPushed.psm1"

function Initialize-LocalActionAssertPushedNotTracked(
    [string] $branchName
) {
    Initialize-RemoteBranchNotTracked $branchName
}

function Initialize-LocalActionAssertPushedSuccess(
    [string] $branchName
) {
    Initialize-RemoteBranchInSync $branchName
}

function Initialize-LocalActionAssertPushedAhead(
    [string] $branchName
) {
    Initialize-RemoteBranchAhead $branchName
}

Export-ModuleMember -Function Initialize-LocalActionAssertPushedNotTracked, Initialize-LocalActionAssertPushedSuccess, Initialize-LocalActionAssertPushedAhead
