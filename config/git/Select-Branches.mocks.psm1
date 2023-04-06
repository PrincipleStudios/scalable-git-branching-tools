Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-Branches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Select-Branches' @PSBoundParameters
}

function Initialize-SelectBranches($branches) {
    $remote = $(Get-Configuration).remote
    if ($remote -ne $nil) {
        Invoke-MockGit 'branch -r' -MockWith $branches
    } else {
        Invoke-MockGit 'branch' -MockWith $branches
    }
}
Export-ModuleMember -Function Initialize-SelectBranches
