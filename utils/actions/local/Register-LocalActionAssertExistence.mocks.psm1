Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionAssertExistence.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Register-LocalActionAssertExistence' @PSBoundParameters
}

function Initialize-LocalActionAssertExistence(
    [Parameter(Mandatory)][AllowEmptyCollection()] $branches,
    [Parameter(Mandatory)][bool] $shouldExist
) {
    $remote = $(Get-Configuration).remote
        
    foreach ($branch in $branches) {
        $actualBranch = ($null -eq $remote) ? $branch : "$remote/$branch"
        Invoke-MockGit "rev-parse --verify $actualBranch" -MockWith ($shouldExist ? 'resolved-commit' : { $global:LASTEXITCODE = 128 })
    }
}

Export-ModuleMember -Function Initialize-LocalActionAssertExistence
