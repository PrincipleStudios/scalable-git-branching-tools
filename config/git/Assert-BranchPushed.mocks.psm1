Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Assert-BranchPushed.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Assert-BranchPushed' @PSBoundParameters
}

function Initialize-BranchPushed([String] $branchName) {
    $remote = $(Get-Configuration).remote
    $remoteBranch = "$remote/$branchName"

    Invoke-MockGit "show-ref --verify --quiet refs/heads/$($branchName)"
    Invoke-MockGit "rev-parse --abbrev-ref --symbolic-full-name $($branchName)@{u}" -MockWith $remoteBranch
    Invoke-MockGit "rev-list --count ^$remoteBranch $branchName" -MockWith 0
}

function Initialize-BranchNotPushed([String] $branchName) {
    $remote = $(Get-Configuration).remote
    $remoteBranch = "$remote/$branchName"

    Invoke-MockGit "show-ref --verify --quiet refs/heads/$($branchName)"
    Invoke-MockGit "rev-parse --abbrev-ref --symbolic-full-name $($branchName)@{u}" -MockWith $remoteBranch
    Invoke-MockGit "rev-list --count ^$remoteBranch $branchName" -MockWith 1
}

function Initialize-BranchNoUpstream([String] $branchName) {
    Invoke-MockGit "show-ref --verify --quiet refs/heads/$($branchName)"
    Invoke-MockGit "rev-parse --abbrev-ref --symbolic-full-name $($branchName)@{u}" -MockWith $nil
}

function Initialize-BranchDoesNotExist([String] $branchName) {
    Invoke-MockGit "show-ref --verify --quiet refs/heads/$($branchName)" -MockWith { $Global:LASTEXITCODE = 1 }
    Invoke-MockGit "rev-parse --abbrev-ref --symbolic-full-name $($branchName)@{u}" -MockWith $nil
}

Export-ModuleMember -Function Initialize-BranchPushed, Initialize-BranchNotPushed, Initialize-BranchNoUpstream, Initialize-BranchDoesNotExist
