Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

$localActions = @{}
function Get-LocalActionsRegistry {
    return $localActions
}

function Get-LocalAction([string] $type) {
    return $localActions[$type]
}

function Invoke-LocalAction(
    [PSObject] $actionDefinition,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    $actionDefinition = ConvertTo-Hashtable $actionDefinition

    # look up type
    $targetAction = Get-LocalAction $actionDefinition.type
    if ($null -eq $targetAction) {
        Add-ErrorDiagnostic $diagnostics "Could not find local action type '$($actionDefinition.type)'"
        return $null
    }

    # if a condition is specified, ensure it is truthy
    if ($actionDefinition.Keys -contains 'condition' -AND -not $actionDefinition.condition) {
        return $null
    }

    # run
    $parameters = ConvertTo-Hashtable $actionDefinition.parameters
    try {
        $outputs = & $targetAction @parameters -diagnostics $diagnostics
    } catch {
        Write-Host "ex: $_"
        Add-ErrorDiagnostic $diagnostics "Unhandled exception occurred while running $(ConvertTo-Json $actionDefinition -Depth 10):"
        Add-ErrorException $diagnostics $_
    }

    return $outputs
}

Export-ModuleMember -Function Invoke-LocalAction, Get-LocalAction, Get-LocalActionsRegistry
