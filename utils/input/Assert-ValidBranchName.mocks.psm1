Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Assert-ValidBranchName.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Assert-ValidBranchName' @PSBoundParameters
}

function Initialize-AssertValidBranchName([String] $branchName) {
    Invoke-MockGit "check-ref-format --branch $($branchName)"
}

function Initialize-AssertInvalidBranchName([String] $branchName) {
    Invoke-MockGit "check-ref-format --branch $($branchName)" -MockWith { $Global:LASTEXITCODE = 1 }
}

Export-ModuleMember -Function Initialize-AssertValidBranchName, Initialize-AssertInvalidBranchName
