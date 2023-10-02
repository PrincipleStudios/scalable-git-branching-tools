Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionSetBranches.psm1"

function Initialize-FinalizeActionSetBranches([Hashtable] $branches, [switch] $fail) {
    $config = Get-Configuration
    
    if ($config.remote -ne $nil) {
        $atomicPart = $config.atomicPushEnabled ? "--atomic " : ''
        $branchList = ConvertTo-PushBranchList $branches
        Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
            -gitCli "push $($config.remote) $atomicPart$branchList" `
            -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
    } else {
        foreach ($key in $branches.Keys) {
            Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' `
                -gitCli "branch $($key) $($branches[$key]) -f" `
                -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
        }
    }
}

Export-ModuleMember -Function Initialize-FinalizeActionSetBranches
