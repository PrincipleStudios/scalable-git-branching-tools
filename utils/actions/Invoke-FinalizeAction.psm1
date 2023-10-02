Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/finalize/Register-FinalizeActionCheckout.psm1"
Import-Module -Scope Local "$PSScriptRoot/finalize/Register-FinalizeActionSetBranches.psm1"

$finalizeActions = @{}
Register-FinalizeActionCheckout $finalizeActions
Register-FinalizeActionSetBranches $finalizeActions

function Invoke-FinalizeAction(
    [PSObject] $actionDefinition,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    # look up type
    $targetAction = $finalizeActions[$actionDefinition.type]
    if ($null -eq $targetAction) {
        Add-ErrorDiagnostic $diagnostics "Could not find finalize action type '$($actionDefinition.type)'"
        return $null
    }

    # run
    $displayName = $actionDefinition.displayName ?? $actionDefinition.id ?? "task of type $($actionDefinition.type)"
    $parameters = ConvertTo-Hashtable $actionDefinition.parameters
    try {
        $outputs = & $targetAction @parameters -diagnostics $diagnostics
    } catch {
        Add-ErrorDiagnostic $diagnostics "Unhandled exception occurred while running '$displayName':"
        Add-ErrorException $diagnostics $_
    }

    return $outputs
}

Export-ModuleMember -Function Invoke-FinalizeAction
