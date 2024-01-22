Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionAssertExistence.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionAssertExistence

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionAssertPushed.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionAssertPushedNotTracked, Initialize-LocalActionAssertPushedSuccess, Initialize-LocalActionAssertPushedAhead

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionGetUpstream.mocks.psm1"
Export-ModuleMember -Function Initialize-UpstreamBranches

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionMergeBranches.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionMergeBranches,Initialize-LocalActionMergeBranchesFailure,Initialize-LocalActionMergeBranchesSuccess

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionSetUpstream.mocks.psm1"
Export-ModuleMember -Function Lock-LocalActionSetUpstream, Initialize-LocalActionSetUpstream

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionSimplifyUpstreamBranches.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionSimplifyUpstreamBranchesSuccess,Initialize-LocalActionSimplifyUpstreamBranches

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionUpstreamsUpdated.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionUpstreamsUpdated

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionValidateBranchNames.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionValidateBranchNamesSuccess

Import-Module -Scope Local "$PSScriptRoot/actions/finalize/Register-FinalizeActionCheckout.mocks.psm1"
Export-ModuleMember -Function Initialize-FinalizeActionCheckout

Import-Module -Scope Local "$PSScriptRoot/actions/finalize/Register-FinalizeActionSetBranches.mocks.psm1"
Export-ModuleMember -Function Initialize-FinalizeActionSetBranches

Import-Module -Scope Local "$PSScriptRoot/actions/finalize/Register-FinalizeActionTrack.mocks.psm1"
Export-ModuleMember -Function Initialize-FinalizeActionTrackDryRun, Initialize-FinalizeActionTrackSuccess
