Import-Module -Scope Local "$PSScriptRoot/Invoke-LocalAction.internal.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAddDiagnostic.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertPushed.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertUpdated.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionEvaluate.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionGetAllUpstreams.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionGetUpstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionGetDownstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionFilterBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionMergeBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionRecurse.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSetUpstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSimplifyUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionUpstreamsUpdated.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionValidateBranchNames.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertExistence.psm1"

$localActions = Get-LocalActionsRegistry
$localActions['add-diagnostic'] = ${function:Invoke-AddDiagnosticLocalAction}
$localActions['assert-existence'] = ${function:Invoke-AssertBranchExistenceLocalAction}
$localActions['assert-pushed'] = ${function:Invoke-AssertBranchPushedLocalAction}
$localActions['assert-updated'] = ${function:Invoke-AssertBranchUpToDateLocalAction}
$localActions['evaluate'] = ${function:Invoke-EvaluateLocalAction}
$localActions['filter-branches'] = ${function:Invoke-FilterBranchesLocalAction}
$localActions['get-all-upstreams'] = ${function:Invoke-GetAllUpstreamsLocalAction}
$localActions['get-downstream'] = ${function:Invoke-GetDownstreamLocalAction}
$localActions['get-upstream'] = ${function:Invoke-GetUpstreamLocalAction}
$localActions['merge-branches'] = ${function:Invoke-MergeBranchesLocalAction}
$localActions['recurse'] = ${function:Invoke-RecursiveScriptLocalAction}
$localActions['set-upstream'] = ${function:Invoke-SetUpstreamLocalAction}
$localActions['simplify-upstream'] = ${function:Invoke-SimplifyUpstreamLocalAction}
$localActions['upstreams-updated'] = ${function:Invoke-UpstreamsUpdatedLocalAction}
$localActions['validate-branch-names'] = ${function:Invoke-AssertBranchNamesLocalAction}

Export-ModuleMember -Function Invoke-LocalAction
