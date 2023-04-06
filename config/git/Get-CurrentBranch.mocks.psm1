Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-CurrentBranch.psm1"

function Initialize-CurrentBranch([string]$branch) {
    Invoke-MockGitModule -ModuleName 'Get-CurrentBranch' -gitCli 'branch --show-current' -MockWith $branch
}

function Initialize-NoCurrentBranch {
    Invoke-MockGitModule -ModuleName 'Get-CurrentBranch' -gitCli 'branch --show-current'
}

Export-ModuleMember -Function Initialize-CurrentBranch, Initialize-NoCurrentBranch
