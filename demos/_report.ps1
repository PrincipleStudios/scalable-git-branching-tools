#!/usr/bin/env pwsh

Get-ChildItem | ForEach-Object { "$($_.Name)`n------------`n$((Get-Content $_) -join "`n")`n`n" }
