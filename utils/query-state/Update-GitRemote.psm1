Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

function Update-GitRemote(
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $prune
) {
    $config = Get-Configuration
    if ($config.remote -eq $nil) { return }
    $pruneArgs = $prune ? @('--prune') : @()
    Invoke-ProcessLogs "git fetch $($config.remote)" {
        git fetch $config.remote -q @pruneArgs
    }

    if ($LASTEXITCODE -ne 0) {
        Add-ErrorDiagnostic $diagnostics "Unable to update remote '$($config.remote)'"
    }
}
Export-ModuleMember -Function Update-GitRemote
