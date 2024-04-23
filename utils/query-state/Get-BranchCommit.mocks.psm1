Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-BranchCommit.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Get-BranchCommit' @PSBoundParameters
}

function Initialize-GetBranchCommit([string] $branch, [string][AllowNull()] $result) {
    Invoke-MockGit "rev-parse --verify $branch" -MockWith {
        if ($result) { $result }
        else { $global:LASTEXITCODE = 1 }
    }.GetNewClosure()
}

Export-ModuleMember -Function Initialize-GetBranchCommit
