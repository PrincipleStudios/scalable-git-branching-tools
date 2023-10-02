Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionSetUpstream.mocks.psm1"
Export-ModuleMember -Function Lock-LocalActionSetUpstream, Initialize-LocalActionSetUpstream

Import-Module -Scope Local "$PSScriptRoot/actions/local/Register-LocalActionCreateBranch.mocks.psm1"
Export-ModuleMember -Function Initialize-LocalActionCreateBranchSuccess

Import-Module -Scope Local "$PSScriptRoot/actions/finalize/Register-FinalizeActionCheckout.mocks.psm1"
Export-ModuleMember -Function Initialize-FinalizeActionCheckout

Import-Module -Scope Local "$PSScriptRoot/actions/finalize/Register-FinalizeActionSetBranches.mocks.psm1"
Export-ModuleMember -Function Initialize-FinalizeActionSetBranches
