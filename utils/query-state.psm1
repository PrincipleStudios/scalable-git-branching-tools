Import-Module -Scope Local "$PSScriptRoot/query-state/Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Update-GitRemote.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Compress-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-UpstreamBranch.psm1"

Export-ModuleMember -Function Get-Configuration `
    , Update-GitRemote `
    , Assert-CleanWorkingDirectory `
    , Compress-UpstreamBranches `
    , Select-UpstreamBranches `
    , Get-UpstreamBranch
