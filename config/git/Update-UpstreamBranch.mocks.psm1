Import-Module -Scope Local "$PSScriptRoot/../testing/Invoke-MockGitModule.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/Update-UpstreamBranch.psm1"

function Initialize-UpdateUpstreamBranch([string] $commitish, [switch] $fail) {
    $config = Get-Configuration
    $command = $config.remote -ne $nil `
        ? "push $($config.remote) $($commitish):refs/heads/$($config.upstreamBranch)" `
        : "branch $($config.upstreamBranch) $($commitish) -f"
    Invoke-MockGitModule -ModuleName 'Update-UpstreamBranch' -gitCli $command -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
}

Export-ModuleMember -Function Initialize-UpdateUpstreamBranch
