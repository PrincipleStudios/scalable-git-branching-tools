Import-Module -Scope Local "$PSScriptRoot/actions/Invoke-LocalAction.psm1"
Export-ModuleMember -Function Invoke-LocalAction

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionAddDiagnostic.psm1"
Export-ModuleMember -Function Invoke-AddDiagnosticLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionAssertExistence.psm1"
Export-ModuleMember -Function Invoke-AssertExistenceLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionAssertPushed.psm1"
Export-ModuleMember -Function Invoke-AssertPushedLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionAssertUpdated.psm1"
Export-ModuleMember -Function Invoke-AssertBranchUpToDateLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionFilterBranches.psm1"
Export-ModuleMember -Function Invoke-FilterBranchesLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionGetAllUpstreams.psm1"
Export-ModuleMember -Function Invoke-GetAllUpstreamsLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionGetDownstream.psm1"
Export-ModuleMember -Function Invoke-GetDownstreamLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionGetUpstream.psm1"
Export-ModuleMember -Function Invoke-GetUpstreamLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionMergeBranches.psm1"
Export-ModuleMember -Function Invoke-MergeBranchesLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionSetUpstream.psm1"
Export-ModuleMember -Function Invoke-SetUpstreamLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionSimplifyUpstreamBranches.psm1"
Export-ModuleMember -Function Invoke-SimplifyUpstreamBranchesLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionUpstreamsUpdated.psm1"
Export-ModuleMember -Function Invoke-UpstreamsUpdatedLocalAction
Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionValidateBranchNames.psm1"
Export-ModuleMember -Function Invoke-ValidateBranchNamesLocalAction


Import-Module -Scope Local "$PSScriptRoot/actions/Invoke-FinalizeAction.psm1"
Export-ModuleMember -Function Invoke-FinalizeAction
