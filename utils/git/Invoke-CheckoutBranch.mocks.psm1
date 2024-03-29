Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-CheckoutBranch.psm1"

function Initialize-CheckoutBranch([string]$branchName) {
    Mock -ModuleName 'Invoke-CheckoutBranch' -CommandName Write-Host {}
    Invoke-MockGitModule -ModuleName 'Invoke-CheckoutBranch' -gitCli "checkout $branchName"
}
function Initialize-CheckoutBranchFailed([string]$branchName) {
    Mock -ModuleName 'Invoke-CheckoutBranch' -CommandName Write-Host {}
    Invoke-MockGitModule -ModuleName 'Invoke-CheckoutBranch' -gitCli "checkout $branchName" -MockWith { $Global:LASTEXITCODE = 1 }
}

Export-ModuleMember -Function Initialize-CheckoutBranch, Initialize-CheckoutBranchFailed
