# Useful for development to reset all of our modules

function Reset-GitModules() {
    Get-ChildItem -Path "$PSScriptRoot" -Include "*.psm1" -Recurse | ForEach-Object {
        Write-Host "Loading $($_.FullName)"
        Import-Module -Scope Local $_.FullName -Force
    }
}
