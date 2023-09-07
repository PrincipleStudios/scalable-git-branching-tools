Import-Module -Scope Local "$PSScriptRoot/query-state/Configuration.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/query-state/Update-GitRemote.mocks.psm1"

Export-ModuleMember -Function Initialize-ToolConfiguration,Initialize-UpdateGitRemote
