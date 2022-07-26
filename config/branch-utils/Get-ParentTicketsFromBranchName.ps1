. $PSScriptRoot/ConvertTo-BranchInfo.ps1

function Get-ParentTicketsFromBranchName([String]$branchName) {
    $info = ConvertTo-BranchInfo $branchName

    $parentTickets = $info.tickets
    if ($parentTickets -eq $nil -AND $info.parents -ne $nil) {
        $parentTickets = $info.parents[-1]
    }
    if ($parentTickets -eq $nil) {
        $parentTickets = @()
    }
    $parentTickets = [string[]]($parentTickets | ForEach-Object {$_}) # flatten the array
    return $parentTickets
}
