Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionSetBranches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' @PSBoundParameters
}

function Initialize-FinalizeActionSetBranches([Hashtable] $branches, [string[]] $track, [switch] $fail) {
    $config = Get-Configuration
    
    foreach ($branch in $branches.Keys) {
        Initialize-AssertValidBranchName $branch
    }

    if ($null -ne $config.remote) {
        $atomicPart = $config.atomicPushEnabled ? "--atomic " : ''
        $branchList = ConvertTo-PushBranchList $branches
        Invoke-MockGit -gitCli "push $($config.remote) $atomicPart$branchList" `
            -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})

        foreach ($branch in $track) {
            Invoke-MockGit `
                -gitCli "branch $($branch) $($branches[$branch]) -f" `
                -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
            Invoke-MockGit -gitCli "branch $branch --set-upstream-to $($config.remote)/$branch"
        }
    } else {
        foreach ($key in $branches.Keys) {
            Invoke-MockGit `
                -gitCli "branch $($key) $($branches[$key]) -f" `
                -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
        }
    }
}

Export-ModuleMember -Function Initialize-FinalizeActionSetBranches
