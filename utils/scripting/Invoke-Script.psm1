Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../actions.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedAnything.psm1"

function Invoke-Script(
    [Parameter(Mandatory)][PSObject] $script,
    [PSObject] $params,
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $dryRun
) {
    $actions = @{}
    $params = $params ?? @{}

    for ($i = 0; $i -lt $script.local.Count; $i++) {
        $name = $script.local[$i].id ?? "#$($i + 1) (1-based)";
        $local = ConvertFrom-ParameterizedAnything -script $script.local[$i] -params $params -actions $actions -diagnostics $diagnostics
        if ($local.fail) {
            Add-ErrorDiagnostic $diagnostics "Could not apply parameters to local action $name; see above errors."
            continue;
        }
        try {
            $outputs = Invoke-LocalAction $local.result -diagnostics $diagnostics
            if ($null -ne $local.result.id -AND $null -ne $outputs) {
                $actions += @{ $local.result.id = @{ outputs = $outputs } }
            }
        } catch {
            Add-ErrorDiagnostic $diagnostics "Encountered error while running local action $($name): see the following error."
            Add-ErrorException $diagnostics $_
        }
    }

    Assert-Diagnostics $diagnostics

    $allFinalize = ConvertFrom-ParameterizedAnything -script $script.finalize -params $params -actions $actions -diagnostics $diagnostics
    if ($allFinalize.fail) {
        Add-ErrorDiagnostic $diagnostics "Could not apply parameters for finalize actions; see above errors."
        Assert-Diagnostics $diagnostics
    }

    $allFinalizeScripts = $allFinalize.result
    if ($dryRun) {
        # TODO: describe this rather than dumping JSON
        Write-Host (ConvertTo-Json $allFinalizeScripts)
    } else {
        for ($i = 0; $i -lt $allFinalizeScripts.Count; $i++) {
            $name = $allFinalizeScripts[$i].id ?? "#$($i + 1) (1-based)";
            $finalize = ConvertFrom-ParameterizedAnything -script $allFinalizeScripts[$i] -params $params -actions $actions -diagnostics $diagnostics
            if ($finalize.fail) {
                Add-ErrorDiagnostic $diagnostics "Could not apply parameters to local action $name; see above errors."
            }
            try {
                $outputs = Invoke-FinalizeAction $finalize.result -diagnostics $diagnostics
                if ($null -ne $finalize.result.id -AND $null -ne $outputs) {
                    $actions += @{ $finalize.result.id = $outputs }
                }
            } catch {
                Add-ErrorDiagnostic $diagnostics "Encountered error while running finalize action $($name): see the following error."
                Add-ErrorException $diagnostics $_
            }
            Assert-Diagnostics $diagnostics
        }
    }
}

Export-ModuleMember -Function Invoke-Script
