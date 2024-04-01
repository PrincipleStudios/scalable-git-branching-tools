# Useful for development to reset all of our modules

Get-Module -All | Where-Object { $_.Path.StartsWith($PSScriptRoot) } | ForEach-Object {
    $current = $_
    if ($null -ne (Get-Module -All | Where-Object { $_.Name -eq $current.Name })) {
        Write-Host "Unloading $($_.Name)..."
        Remove-Module $_.Name -Force
    }
}
