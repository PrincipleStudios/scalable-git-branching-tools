Import-Module -Scope Local "$PSScriptRoot/input/Assert-ValidBranchName.mocks.psm1"
Export-ModuleMember -Function Initialize-AssertValidBranchName, Initialize-AssertInvalidBranchName
