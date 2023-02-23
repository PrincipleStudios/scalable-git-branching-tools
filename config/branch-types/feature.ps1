. $PSScriptRoot/Variables.ps1
. $PSScriptRoot/../core/coalesce.ps1
. $PSScriptRoot/format-branch.ps1

$featureTypePartialRegex = '(feature|bugfix)'
$featureTypeRegex = "^$featureTypePartialRegex$"

function Format-GitFeature($type, $tickets, $comments) { return Format-Branch (coalesce $type 'feature') $tickets -m $comments }
function ConvertTo-GitFeatureInfo($branchName) {
    if ($branchName -notmatch $branchTypeFeature.regex) {
        return $nil
    }

    $result = @{ type = $Matches.type; ticket = $Matches.ticket }
    if ($Matches.comment -ne $nil) {
        $result.comment = $Matches.comment
    }
    if ($Matches.parentTickets -ne $nil) {
        $result.parents = [string[]]($Matches.parentTickets.split('_') | Where-Object { $_ -ne "" })
    }
    return $result
}

$branchTypeFeature = @{
    type = $featureTypeRegex
    regex = "^(?<type>$featureTypePartialRegex)/(?<parentTickets>($ticketPartialRegex$parentTicketDelimeter)+)?(?<ticket>$ticketPartialRegex)(-(?<comment>$commentPart))?$"
    build = 'Format-GitFeature'
    toInfo = 'ConvertTo-GitFeatureInfo'
}