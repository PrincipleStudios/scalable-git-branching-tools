. $PSScriptRoot/../Variables.ps1

function Assert-TicketName($ticketName, [switch] $optional) {
    if ($optional -AND $ticketName -eq '') {
        return
    }
    if ($ticketName -notmatch $ticketRegex) {
        throw "The ticket name '$ticketName' is not valid.";
    }
}