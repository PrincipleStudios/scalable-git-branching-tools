Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/../git/Get-GitFile.mocks.psm1"

function Initialize-AnyUpstreamBranches() {
    $upstream = Get-UpstreamBranch
    Initialize-OtherGitFilesAsBlank $upstream
}

function Initialize-UpstreamBranches([PSObject] $upstreamConfiguration) {
    $upstream = Get-UpstreamBranch
    $upstreamConfiguration.Keys | Foreach-Object {
        Initialize-GitFile $upstream $_ $upstreamConfiguration[$_]
    }
}
Export-ModuleMember -Function Initialize-AnyUpstreamBranches,Initialize-UpstreamBranches
