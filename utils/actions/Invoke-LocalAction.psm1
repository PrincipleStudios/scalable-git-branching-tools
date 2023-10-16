Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionAssertPushed.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSetUpstream.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionCreateBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionSimplifyUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/local/Register-LocalActionValidateBranchNames.psm1"

$localActions = @{}
Register-LocalActionAssertPushed $localActions
Register-LocalActionSetUpstream $localActions
Register-LocalActionCreateBranch $localActions
Register-LocalActionSimplifyUpstreamBranches $localActions
Register-LocalActionValidateBranchNames $localActions

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

Export-ModuleMember -Function Invoke-LocalAction
