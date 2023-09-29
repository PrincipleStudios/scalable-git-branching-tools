Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionSetUpstream.mocks.psm1"
Export-ModuleMember -Function Lock-LocalActionSetUpstream, Initialize-LocalActionSetUpstream

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionCreateBranch.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionCreateBranchSuccess
