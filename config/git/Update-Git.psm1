Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"

function Update-Git([switch] $prune) {
    $config = Get-Configuration
    if ($config.remote -eq $nil) { return }
    Write-Host "Performing 'git fetch $($config.remote)'..."
    $pruneArgs = $prune ? @('--prune') : @()
    git fetch $config.remote -q @pruneArgs

    if ($LASTEXITCODE -ne 0) {
        throw 'git fetch failed'
    }
}
Export-ModuleMember -Function Update-Git
