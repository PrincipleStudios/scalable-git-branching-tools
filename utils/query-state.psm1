Import-Module -Scope Local "$PSScriptRoot/query-state/Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Update-GitRemote.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Assert-CleanWorkingDirectory.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Compress-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Select-UpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-CurrentBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Get-MergeTree.psm1"

Export-ModuleMember -Function Get-Configuration `
    , Update-GitRemote `
    , Assert-CleanWorkingDirectory `
    , Compress-UpstreamBranches `
    , Select-UpstreamBranches `
    , Get-UpstreamBranch `
    , Get-CurrentBranch `
    , Get-GitFile `
    , Get-MergeTree `

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-BranchSyncState.psm1"
Export-ModuleMember -Function Get-BranchSyncState

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-BranchCommit.psm1"
Export-ModuleMember -Function Get-BranchCommit

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-LocalBranchForRemote.psm1"
Export-ModuleMember -Function Get-LocalBranchForRemote

Import-Module -Scope Local "$PSScriptRoot/query-state/Get-RemoteBranchRef.psm1"
Export-ModuleMember -Function Get-RemoteBranchRef

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-Branches.psm1"
Export-ModuleMember -Function Select-Branches

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-AllUpstreamBranches.psm1"
Export-ModuleMember -Function Select-AllUpstreamBranches

Import-Module -Scope Local "$PSScriptRoot/query-state/Select-DownstreamBranches.psm1"
Export-ModuleMember -Function Select-DownstreamBranches
