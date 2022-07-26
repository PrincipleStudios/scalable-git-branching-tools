. $PSScriptRoot/Get-Configuration.ps1

function Update-Git() {
    $config = Get-Configuration
    if ($config.remote -eq $nil) { return }
    Write-Host "Performing 'git fetch $($config.remote)'..."
    git fetch $config.remote -q
    
    if ($LASTEXITCODE -ne 0) {
        throw 'git fetch failed'
    }
}
