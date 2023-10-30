Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.mocks.psm1"

function Initialize-UpstreamBranches([PSObject] $upstreamConfiguration) {
    Initialize-AllUpstreamBranches $upstreamConfiguration
}
Export-ModuleMember -Function Initialize-UpstreamBranches
