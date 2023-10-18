Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionXxx.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Register-FinalizeActionXxx' @PSBoundParameters
}

function Initialize-FinalizeActionXxxSuccess() {
}

Export-ModuleMember -Function Initialize-FinalizeActionXxxSuccess
