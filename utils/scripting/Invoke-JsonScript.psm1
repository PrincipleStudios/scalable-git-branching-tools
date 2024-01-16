Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../actions.psm1"
Import-Module -Scope Local "$PSScriptRoot/Invoke-Script.psm1"

function Invoke-JsonScript(
    [Parameter(Mandatory)][string] $scriptPath,
    [Parameter(Mandatory)][PSObject] $params,
    [switch] $dryRun,
    [switch] $noFetch,
    [switch] $quiet
) {
    $diagnostics = New-Diagnostics
    if (-not $noFetch) {
        Update-GitRemote -quiet:$quiet
    }
    $instructions = Get-Content $scriptPath | ConvertFrom-Json
    Invoke-Script $instructions -params $params -diagnostics $diagnostics -dryRun:$dryRun
}

Export-ModuleMember -Function Invoke-JsonScript
