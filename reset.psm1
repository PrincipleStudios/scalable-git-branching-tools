# Useful for development to reset all of our modules

function Reset-GitModules() {
    $localModules = ((Get-ChildItem -Path "." -Include "*.psm1" -Recurse) | ForEach-Object { $_.FullName })
    Get-Module -All | Where-Object { $localModules -contains $_.Path } | ForEach-Object {
        Write-Host "Unloading $($_.Name)..."
        Remove-Module $_.Name -Force
    }
}
