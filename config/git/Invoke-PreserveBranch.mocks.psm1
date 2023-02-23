Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Invoke-PreserveBranch' @PSBoundParameters
}

function Initialize-PreserveBranchNoCleanup([string] $detachedHead) {
    if ($detachedHead -ne $nil -AND $detachedHead -ne '') {
        Invoke-MockGit 'rev-parse HEAD' $detachedHead
    }
}
function Initialize-PreserveBranchCleanup([string] $detachedHead) {
    if ($detachedHead -eq $nil -OR $detachedHead -eq '') {
        $resetTo = Get-CurrentBranch
    } else {
        $resetTo = $detachedHead
        Invoke-MockGit 'rev-parse HEAD' $detachedHead
    }

    Invoke-MockGit 'reset --hard'
    Invoke-MockGit "checkout $resetTo"
}

Export-ModuleMember -Function Initialize-PreserveBranchNoCleanup,Initialize-PreserveBranchCleanup
