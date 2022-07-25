function Get-Tickets {
    [OutputType([string[]])]
    param([PSObject]$branchInfo)
    return [string[]]($branchInfo.ticket -eq $nil ? $branchInfo.tickets : @($branchInfo.ticket))
}