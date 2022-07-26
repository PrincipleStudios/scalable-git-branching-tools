. $PSScriptRoot/Get-Tickets.ps1

function Invoke-TicketsToBranches([string[]]$desiredTickets, [PSObject[]] $allBranchInfo) {
    return $allBranchInfo | Where-Object {
        $branchTickets = [string[]](Get-Tickets $_)
        if ($branchTickets.Length -eq 0) { return $false }
        $intersection = [string[]]($branchTickets | Where-Object { $desiredTickets -contains $_ })
        return $intersection.Length -eq $branchTickets.Length -AND $_.branch -ne $branchName
    }
}
