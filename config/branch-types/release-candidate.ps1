. $PSScriptRoot/../Variables.ps1
. $PSScriptRoot/../core/coalesce.ps1
. $PSScriptRoot/../core/format-branch.ps1

function Format-GitReleaseCandidate($type, $tickets, $comments) { return Format-Branch 'rc' @() $comments }
function ConvertTo-GitReleaseCandidateInfo($branchName) {
    if ($branchName -notmatch $branchTypeReleaseCandidate.regex) {
        return $nil
    }
    return @{ type = 'rc'; comment = $Matches.comment }
}

$branchTypeReleaseCandidate = @{
    regex = "^rc/(?<comment>$commentPart)$"
    build = 'Format-GitReleaseCandidate'
    toInfo = 'ConvertTo-GitReleaseCandidateInfo'
}