Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../actions.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedAnything.psm1"

function Invoke-Script(
    [PSObject] $script,
    [PSObject] $params,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    $actions = @{}
    $unresolvedTasks = New-Object System.Collections.ArrayList
    $unresolvedTasks.AddRange($script.local)
    for ($i = 0; $i -lt $unresolvedTasks.Count; $i++) {
        $local = ConvertFrom-ParameterizedAnything -script $unresolvedTasks[$i] -params $params -actions $actions
        if ($local.fail) { continue; }
        $outputs = Invoke-LocalAction $local.result -diagnostics $diagnostics
        $unresolvedTasks.RemoveAt($i)
        $i--;
        if ($null -ne $local.result.id -AND $null -ne $outputs) {
            $actions[$local.result.id] = $outputs
            # Return to the beginning to see if the local tasks were out of order
            $i = -1
        }
    }
    if ($unresolvedTasks.Count -gt 0) {
        Show-ProcessLogs
        for ($i = 0; $i -lt $unresolvedTasks.Count; $i++) {
            $local = ConvertFrom-ParameterizedAnything -params $params -actions $actions -diagnostics $diagnostics
        }
        Add-ErrorDiagnostic $diagnostics 'At least one task could not be parsed; see the above warnings'
        return
    }

    # TODO - do finalize scripts
    Write-Host (ConvertTo-Json $actions)
}

Export-ModuleMember -Function Invoke-Script
