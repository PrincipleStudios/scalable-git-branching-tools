Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/finalize/Register-FinalizeActionCheckout.psm1"
Import-Module -Scope Local "$PSScriptRoot/finalize/Register-FinalizeActionSetBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/finalize/Register-FinalizeActionTrack.psm1"

$finalizeActions = @{}
Register-FinalizeActionCheckout $finalizeActions
Register-FinalizeActionSetBranches $finalizeActions
Register-FinalizeActionTrack $finalizeActions

function Invoke-FinalizeAction(
    [PSObject] $actionDefinition,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    $actionDefinition = ConvertTo-Hashtable $actionDefinition

    # look up type
    $targetAction = $finalizeActions[$actionDefinition.type]
    if ($null -eq $targetAction) {
        Add-ErrorDiagnostic $diagnostics "Could not find finalize action type '$($actionDefinition.type)'"
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
        Add-ErrorDiagnostic $diagnostics "Unhandled exception occurred while running '$(ConvertTo-Json $actionDefinition -Depth 10)':"
        Add-ErrorException $diagnostics $_
    }

    return $outputs
}

Export-ModuleMember -Function Invoke-FinalizeAction
