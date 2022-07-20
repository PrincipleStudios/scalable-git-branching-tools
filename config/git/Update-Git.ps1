. $PSScriptRoot/Get-Configuration.ps1

function Update-Git() {
    $config = Get-Configuration
    Write-Host "Performing 'git fetch $($config.remote)'..."
    git fetch $config.remote -q
    
    if ($LASTEXITCODE -ne 0) {
        throw 'git fetch failed'
    }
}
