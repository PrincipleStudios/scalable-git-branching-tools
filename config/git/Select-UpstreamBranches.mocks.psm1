Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.mocks.psm1"

function Initialize-UpstreamBranches([PSObject] $upstreamConfiguration) {
    $upstream = Get-UpstreamBranch

    $upstreamConfiguration.Keys | Foreach-Object {
        Initialize-GitFile $upstream $_ $upstreamConfiguration[$_]
    }
}
Export-ModuleMember -Function Initialize-UpstreamBranches
