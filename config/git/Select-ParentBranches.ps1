. $PSScriptRoot/../core/Coalesce.ps1
. $PSScriptRoot/../branch-utils/ConvertTo-BranchInfo.ps1
. $PSScriptRoot/../branch-utils/Get-Tickets.ps1
. $PSScriptRoot/Select-Branches.ps1

function Select-ParentBranches([String]$branchName) {
    # TODO: check "config branch" for things like RC branches
    $branches = Select-Branches

    $info = ConvertTo-BranchInfo $branchName

    $parentTickets = $info.tickets
    if ($parentTickets -eq $nil -AND $info.parents -ne $nil) {
        $parentTickets = $info.parents[-1]
    }
    if ($parentTickets -eq $nil) {
        $parentTickets = @()
    }
    $parentTickets = $parentTickets | ForEach-Object {$_} # flatten the array
    if ($parentTickets.Length -eq 0) {
        return $branches | Where-Object { $_.type -eq 'service-line' } | ForEach-Object { $_.branch }
    } else {
        return $branches | Where-Object {
            $tickets = (Get-Tickets $_)
            if ($tickets.Length -eq 0) { return $false }
            $intersection = $tickets | Where-Object { $parentTickets -contains $_ }
            return $intersection.Length -eq $tickets.Length -AND $_.branch -ne $branchName
        } | ForEach-Object { $_.branch }
    }
}
