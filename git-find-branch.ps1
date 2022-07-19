#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][String] $ticketName
)

. $PSScriptRoot/config/Common.ps1

Assert-TicketName $ticketName
$remotes = git remote

Select-Branches | Select Branch,Remote,Type,Ticket,Tickets,Parents,Comment | Where-Object { $_.ticket -eq $ticketName } | Format-Table
