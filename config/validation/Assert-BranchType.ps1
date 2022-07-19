. $PSScriptRoot/../branch-types.ps1

function Get-BranchType($type) {
    return ($branchTypes.Keys
        | Where-Object { $type -match $branchTypes[$_].type }
        | Select-Object -First 1)
}

function Assert-BranchType($type, [switch] $optional) {
    if ($optional -AND $type -eq '') {
        return
    }
    if ((Get-BranchType $type) -eq $nil) {
        throw "The branch type '$type' is not valid.";
    }
}