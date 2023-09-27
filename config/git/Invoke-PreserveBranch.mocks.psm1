Import-Module -Scope Local "$PSScriptRoot/../../utils/testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Invoke-PreserveBranch' @PSBoundParameters
}

function Initialize-GetGitDetachedHead([string] $detachedHead) {
    Invoke-MockGit 'rev-parse HEAD' $detachedHead
}

function Initialize-RestoreGitHead([string] $previousHead) {
    Invoke-MockGit 'reset --hard'
    Invoke-MockGit "checkout $previousHead"
}

function Initialize-PreserveBranchNoCleanup([string] $detachedHead) {
    if ($detachedHead -ne $nil -AND $detachedHead -ne '') {
        Initialize-GetGitDetachedHead $detachedHead
    }
}
function Initialize-PreserveBranchCleanup([string] $detachedHead) {
    if ($detachedHead -eq $nil -OR $detachedHead -eq '') {
        $resetTo = Get-CurrentBranch
    } else {
        $resetTo = $detachedHead
        Initialize-GetGitDetachedHead $detachedHead
    }

    Initialize-RestoreGitHead $resetTo
}

Export-ModuleMember -Function Initialize-GetGitDetachedHead,Initialize-RestoreGitHead,Initialize-PreserveBranchNoCleanup,Initialize-PreserveBranchCleanup
