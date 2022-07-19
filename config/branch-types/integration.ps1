. $PSScriptRoot/../Variables.ps1
. $PSScriptRoot/../core/coalesce.ps1
. $PSScriptRoot/../core/format-branch.ps1

function Format-GitIntegration($type, $tickets) { return Format-Branch 'integrate' $tickets }
function ConvertTo-GitIntegrationInfo($branchName) {
    if ($branchName -notmatch $branchTypeIntegration.regex) {
        return $nil
    }
    $result = @{ type = 'integration' }
    $result.tickets = ,($Matches.tickets.split('_') | Where-Object { $_ -ne "" })
    return $result
}

$branchTypeIntegration = @{
    type = "^(integrate|integration|integ)$"
    regex = "^integrate/(?<tickets>($ticketPartialRegex$parentTicketDelimeter)*$ticketPartialRegex)"
    build = 'Format-GitIntegration'
    toInfo = 'ConvertTo-GitIntegrationInfo'
}