Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-Branches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Select-Branches' @PSBoundParameters
}

function Initialize-SelectBranches([string[]] $branches) {
    $remote = $(Get-Configuration).remote
    if ($remote -ne $nil) {
        $result = ($branches | ForEach-Object { "$remote/$_" })
        Invoke-MockGit 'branch -r' -MockWith $result
    } else {
        Invoke-MockGit 'branch' -MockWith $branches
    }
}
Export-ModuleMember -Function Initialize-SelectBranches
