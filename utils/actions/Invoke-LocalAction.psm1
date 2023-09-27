Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSetUpstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionCreateBranch.psm1"

$localActions = @{}
Register-LocalActionSetUpstream $localActions
Register-LocalActionCreateBranch $localActions

function Invoke-LocalAction(
    [PSObject] $actionDefinition,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    # look up type
    $targetAction = $localActions[$actionDefinition.type]
    if ($null -eq $targetAction) {
        Add-ErrorDiagnostic $diagnostics "Could not find local action type '$($actionDefinition.type)'"
        return $null
    }

    # run
    $displayName = $actionDefinition.displayName ?? $actionDefinition.id ?? "task of type $($actionDefinition.type)"
    $parameters = ConvertTo-Hashtable $actionDefinition.parameters
    try {
        $outputs = & $targetAction @parameters -diagnostics $diagnostics
    } catch {
        throw $_
        Add-ErrorDiagnostic $diagnostics "Unhandled exception occurred while running '$displayName': $_"
    }

    return $outputs
}

Export-ModuleMember -Function Invoke-LocalAction
