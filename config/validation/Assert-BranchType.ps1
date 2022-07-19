. $PSScriptRoot/../branch-utils/Get-BranchType.ps1

function Assert-BranchType($type, [switch] $optional) {
    if ($optional -AND $type -eq '') {
        return
    }
    if ((Get-BranchType $type) -eq $nil) {
        throw "The branch type '$type' is not valid.";
    }
}