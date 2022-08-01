. $PSScriptRoot/Get-Tickets.ps1

function Invoke-TicketsToBranches(
    [Parameter()][string[]]$tickets,
    [Parameter()][String[]]$branches,
    [Parameter(Mandatory)][PSObject[]] $allBranchInfo
) {
    return $allBranchInfo | Where-Object {
        if ($branches -ne $nil -AND $branches -contains $_.branch) { return $true }
        $branchTickets = [string[]](Get-Tickets $_)
        if ($branchTickets.Length -eq 0) { return $false }
        $intersection = [string[]]($branchTickets | Where-Object { $tickets -contains $_ })
        return $intersection.Length -eq $branchTickets.Length -AND $_.branch -ne $branchName
    }
}
