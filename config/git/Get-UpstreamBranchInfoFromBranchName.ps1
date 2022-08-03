. $PSScriptRoot/../branch-utils/ConvertTo-BranchName.ps1
. $PSScriptRoot/../branch-utils/Invoke-TicketsToBranches.ps1
. $PSScriptRoot/../branch-utils/Get-ParentTicketsFromBranchName.ps1
. $PSScriptRoot/Select-Branches.ps1
. $PSScriptRoot/Invoke-SimplifyUpstreamBranches.ps1

function Get-UpstreamBranchInfoFromBranchName([String]$branchName, [PSObject[]] $allBranchInfo, [Parameter(Mandatory)][PSObject] $config) {
    if ($allBranchInfo -eq $nil) {
        $allBranchInfo = Select-Branches -config $config
    }
    
    $parentTickets = [string[]](Get-ParentTicketsFromBranchName $branchName)
    if ($parentTickets.Length -eq 0) {
        $serviceLines = [PSObject[]]($allBranchInfo | Where-Object { $_.type -eq 'service-line' })
        if ($serviceLines.Length -gt 1) {
            $allLines = ($serviceLines | ForEach-Object { ConvertTo-BranchName $_ -includeRemote }) -join ' '
            throw "Found more than one service line ($allLines) - please specify the base."
        }
        return $serviceLines
    } else {
        return Invoke-SimplifyUpstreamBranches (Invoke-TicketsToBranches -tickets $parentTickets -allBranchInfo $allBranchInfo) $allBranchInfo -config $config
    }
}
