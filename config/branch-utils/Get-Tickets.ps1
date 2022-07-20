. $PSScriptRoot/../core/Coalesce.ps1

function Get-Tickets($branchInfo) {
    return Coalesce ($branchInfo.ticket -eq $nil ? $branchInfo.tickets : @($branchInfo.ticket)) @()
}