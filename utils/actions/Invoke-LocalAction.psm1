Import-Module -Scope Local "$PSScriptRoot/Invoke-LocalAction.internal.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAddDiagnostic.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertPushed.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionGetUpstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionFilterBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionMergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionRecurse.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSetUpstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSimplifyUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionUpstreamsUpdated.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionValidateBranchNames.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertExistence.psm1"

$localActions = Get-LocalActionsRegistry
Register-LocalActionAddDiagnostic $localActions
Register-LocalActionAssertPushed $localActions
Register-LocalActionGetUpstream $localActions
Register-LocalActionFilterBranches $localActions
Register-LocalActionMergeBranches $localActions
Register-LocalActionRecurse $localActions
Register-LocalActionSetUpstream $localActions
Register-LocalActionSimplifyUpstreamBranches $localActions
Register-LocalActionUpstreamsUpdated $localActions
Register-LocalActionValidateBranchNames $localActions
Register-LocalActionAssertExistence $localActions

Export-ModuleMember -Function Invoke-LocalAction
