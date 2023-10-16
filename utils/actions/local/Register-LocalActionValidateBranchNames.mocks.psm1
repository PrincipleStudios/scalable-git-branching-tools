Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionValidateBranchNames.psm1"

function Initialize-LocalActionValidateBranchNamesSuccess(
    [string[]] $branches
) {
    foreach ($branch in $branches) {
        Initialize-AssertValidBranchName $branch
    }
}

Export-ModuleMember -Function Initialize-LocalActionValidateBranchNamesSuccess
