Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-CreateBranch.psm1"

function Initialize-CreateBranch([string]$branchName, [string]$source) {
    Invoke-MockGitModule -ModuleName 'Invoke-CreateBranch' -gitCli "branch $branchName $source --quiet --no-track"
}
function Initialize-CreateBranchFailed([string]$branchName) {
    Invoke-MockGitModule -ModuleName 'Invoke-CreateBranch' -gitCli "branch $branchName $source --quiet --no-track" -MockWith { $Global:LASTEXITCODE = 1 }
}

Export-ModuleMember -Function Initialize-CreateBranch, Initialize-CreateBranchFailed
