Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-PreserveBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Invoke-PreserveBranch' @PSBoundParameters
}

function Initialize-PreserveBranchDetachedHead([string] $detachedHead) {
    Invoke-MockGit 'rev-parse HEAD' $detachedHead
}
function Initialize-PreserveBranchCleanup([string] $detachedHead) {
    if ($detachedHead -eq $nil -OR $detachedHead -eq '') {
        $detachedHead = Get-CurrentBranch
    } else {
        Invoke-MockGit 'rev-parse HEAD' $detachedHead
    }

    Invoke-MockGit 'reset --hard'
    Invoke-MockGit "checkout $detachedHead"
}

Export-ModuleMember -Function Initialize-PreserveBranchDetachedHead,Initialize-PreserveBranchCleanup
