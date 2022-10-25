function Update-Git([Parameter(Mandatory)][PSObject] $config) {
    if ($config.remote -eq $nil) { return }
    Write-Host "Performing 'git fetch $($config.remote)'..."
    git fetch $config.remote -q
    
    if ($LASTEXITCODE -ne 0) {
        throw 'git fetch failed'
    }
}
