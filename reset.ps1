# Useful for development to reset all of our modules

Get-Module -All | Where-Object { $_.Path.StartSwith($PSScriptRoot) } | ForEach-Object {
    Write-Host "Unloading $($_.Name)..."
    Remove-Module $_.Name -Force
}
