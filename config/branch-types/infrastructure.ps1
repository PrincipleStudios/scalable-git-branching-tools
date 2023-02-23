. $PSScriptRoot/Variables.ps1
. $PSScriptRoot/../core/coalesce.ps1
. $PSScriptRoot/format-branch.ps1

function Format-GitInfrastructure($type, $tickets, $comment) { return Format-Branch 'infra' $tickets -m $comment }
function ConvertTo-GitInfrastructureInfo($branchName) {
    if ($branchName -notmatch $branchTypeInfrastructure.regex) {
        return $nil
    }
    $result = @{ type = 'infrastructure'; comment = $Matches.comment }
    if ($Matches.tickets -ne $nil) {
        $result.tickets = [string[]](($Matches.tickets.split('_') | Where-Object { $_ -ne "" }))
    }
    return $result
}

$branchTypeInfrastructure = @{
    type = "^(infrastructure|infra)$"
    regex = "^infra/((?<tickets>($ticketPartialRegex$parentTicketDelimeter)*$ticketPartialRegex)-)?(?<comment>$commentPart)$"
    build = 'Format-GitInfrastructure'
    toInfo = 'ConvertTo-GitInfrastructureInfo'
}