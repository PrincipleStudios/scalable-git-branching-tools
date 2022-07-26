. $PSScriptRoot/../branch-utils/ConvertTo-BranchInfo.ps1
. $PSScriptRoot/../branch-utils/Get-Tickets.ps1
. $PSScriptRoot/Get-Configuration.ps1
. $PSScriptRoot/Select-Branches.ps1
. $PSScriptRoot/Get-GitFile.ps1

function ConvertTo-BranchName($branchInfo, [switch] $includeRemote) {
    return ($includeRemote -AND $branchInfo.remote -ne $nil) ? "$($branchInfo.remote)/$($branchInfo.branch)" : $branchInfo.branch
}

function Select-ParentBranches([String]$branchName, [PSObject[]] $allBranchInfo, [switch] $includeRemote) {
    if ($allBranchInfo -eq $nil) {
        $allBranchInfo = Select-Branches
    }

    $config = Get-Configuration
    $parentBranches = Get-GitFile $branchName "$($config.remote)/$($config.upstreamBranch)"
    if ($includeRemote) {
        return $parentBranches | ForEach-Object { "$($config.remote)/$_" }
    } else {
        return $parentBranches
    }
}

function Invoke-FindParentBranchesFromBranchName([String]$branchName, [PSObject[]] $allBranchInfo, [switch] $includeRemote) {
    if ($allBranchInfo -eq $nil) {
        $allBranchInfo = Select-Branches
    }
    
    $info = ConvertTo-BranchInfo $branchName

    $parentTickets = $info.tickets
    if ($parentTickets -eq $nil -AND $info.parents -ne $nil) {
        $parentTickets = $info.parents[-1]
    }
    if ($parentTickets -eq $nil) {
        $parentTickets = @()
    }
    $parentTickets = [string[]]($parentTickets | ForEach-Object {$_}) # flatten the array
    if ($parentTickets.Length -eq 0) {
        $serviceLines = @($allBranchInfo | Where-Object { $_.type -eq 'service-line' } | ForEach-Object { ConvertTo-BranchName $_ -includeRemote:$includeRemote })
        if ($serviceLines.Length -gt 1) {
            $allLines = $serviceLines -join ' '
            throw "Found more than one service line ($serviceLines) - please specify the base."
        }
        return $serviceLines
    } else {
        return Invoke-SimplifyParentBranches (Invoke-ParentTicketsToBranches $parentTickets $allBranchInfo -includeRemote:$includeRemote) $allBranchInfo -includeRemote:$includeRemote
    }
}

function Invoke-ParentTicketsToBranches([string[]]$parentTickets, [PSObject[]] $allBranchInfo, [switch] $includeRemote) {
    return $allBranchInfo | Where-Object {
        $tickets = Get-Tickets $_
        if ($tickets.Length -eq 0) { return $false }
        $intersection = $tickets | Where-Object { $parentTickets -contains $_ }
        return $intersection.Length -eq $tickets.Length -AND $_.branch -ne $branchName
    } | ForEach-Object { ConvertTo-BranchName $_ -includeRemote:$includeRemote }
}

function Invoke-SimplifyParentBranches([string[]] $originalParents, [PSObject[]] $allBranchInfo, [switch] $includeRemote) {
    if ($allBranchInfo -eq $nil) {
        $allBranchInfo = Select-Branches
    }

    $possibleResult = $allBranchInfo | Where { $originalParents -contains (ConvertTo-BranchName $_ -includeRemote:$includeRemote) }
    do {
        $len = $possibleResult.Length
        $parents = $possibleResult | ForEach-Object { return Select-ParentBranches $_.branch -includeRemote:$includeRemote } | ForEach-Object {$_} | select -uniq
        $possibleResult = $possibleResult | Where-Object { $parents -notcontains (ConvertTo-BranchName $_ -includeRemote:$includeRemote) }
    } until ($len -eq $possibleResult.Length)

    return $possibleResult | ForEach-Object { ConvertTo-BranchName $_ -includeRemote:$includeRemote }
}
