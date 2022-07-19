. $PSScriptRoot/../branch-types.ps1

function Get-BranchType($type) {
    return ($branchTypes.Keys
        | Where-Object { $type -match $branchTypes[$_].type }
        | Select-Object -First 1)
}
