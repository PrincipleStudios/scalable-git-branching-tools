#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory, Position=0)][String] $ticketName
)

. $PSScriptRoot/config/Common.ps1

Validate-Ticket $ticketName
$remotes = git remote

List-Branches | Where-Object { $_.ticket -eq $ticketName } | Format-Table
