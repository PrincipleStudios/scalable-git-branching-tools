Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../input.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-FinalizeActionSetBranches.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Register-FinalizeActionSetBranches' @PSBoundParameters
}

function Initialize-FinalizeActionSetBranches(
    [Hashtable] $branches, 
    [switch] $fail, 
    [switch] $force, 
    [switch] $currentBranchDirty
) {
    $config = Get-Configuration
    
    foreach ($branch in $branches.Keys) {
        Initialize-AssertValidBranchName $branch
    }

    if ($null -ne $config.remote) {
        $atomicPart = $config.atomicPushEnabled ? "--atomic " : ''
        $forcePart = $force ? "--force " : ''
        $branchList = ConvertTo-PushBranchList $branches
        Invoke-MockGit -gitCli "push $($config.remote) $atomicPart$forcePart$branchList" `
            -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
    } else {
        $currentBranch = Get-CurrentBranch
        foreach ($key in $branches.Keys) {
            if ($currentBranch -eq $key) {
                if ($currentBranchDirty) {
                    Initialize-DirtyWorkingDirectory
                } else {
                    Initialize-CleanWorkingDirectory
                    Invoke-MockGit `
                        -gitCli "reset --hard $($branches[$key])" `
                        -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
                }
            } else {
                Invoke-MockGit `
                    -gitCli "branch $($key) $($branches[$key]) -f" `
                    -MockWith $($fail ? { $Global:LASTEXITCODE = 1 } : {})
            }
        }
    }
}

Export-ModuleMember -Function Initialize-FinalizeActionSetBranches
