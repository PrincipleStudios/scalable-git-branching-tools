Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../actions.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedAnything.psm1"

function Invoke-Script(
    [Parameter(Mandatory)][PSObject] $script,
    [PSObject] $params,
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $dryRun
) {
    try {
        $config = Get-Configuration
        $actions = @{}
        $params = $params ?? @{}

        for ($i = 0; $i -lt $script.local.Count; $i++) {
            $name = $script.local[$i].id ?? "#$($i + 1) (1-based)";
            $variables = @{ config=$config; params=$params; actions=$actions }
            $local = ConvertFrom-ParameterizedAnything -script $script.local[$i] -variables $variables -diagnostics $diagnostics
            if ($local.fail) {
                Add-ErrorDiagnostic $diagnostics "Could not apply parameters to local action $name; see above errors. Evaluation below:"
                Add-ErrorDiagnostic $diagnostics "$(ConvertTo-Json $local.result -Depth 10)"
                Assert-Diagnostics $diagnostics
            }
            try {
                $outputs = Invoke-LocalAction $local.result -diagnostics $diagnostics
                if ($null -ne $local.result.id) {
                    $actions += @{ $local.result.id = @{ outputs = $outputs } }
                }
            } catch {
                Add-ErrorDiagnostic $diagnostics "Encountered error while running local action $($name), evaluated below, with the error following."
                Add-ErrorDiagnostic $diagnostics "$(ConvertTo-Json $local.result -Depth 10)"
                Add-ErrorException $diagnostics $_
            }
            Assert-Diagnostics $diagnostics
        }

        if ($script.finalize) {
            $variables = @{ config=$config; params=$params; actions=$actions }
            $allFinalize = ConvertFrom-ParameterizedAnything -script $script.finalize -variables $variables -diagnostics $diagnostics
            if ($allFinalize.fail) {
                Add-ErrorDiagnostic $diagnostics "Could not apply parameters for finalize actions; see above errors."
                Assert-Diagnostics $diagnostics
            }

            $allFinalizeScripts = $allFinalize.result
            if ($dryRun) {
                Write-Host -ForegroundColor Yellow "Executing dry run; would run the following commands:"
            }

            for ($i = 0; $i -lt $allFinalizeScripts.Count; $i++) {
                $name = $allFinalizeScripts[$i].id ?? "#$($i + 1) (1-based)";
                $finalize = $allFinalizeScripts[$i]
                try {
                    $outputs = Invoke-FinalizeAction $finalize -diagnostics $diagnostics -dryRun:$dryRun
                    if ($dryRun) {
                        $outputs | Write-Host
                    }
                    if ($null -ne $finalize.id) {
                        $actions += @{ $finalize.id = @{ outputs = $outputs } }
                    }
                } catch {
                    Add-ErrorDiagnostic $diagnostics "Encountered error while running finalize action $($name): see the following error."
                    Add-ErrorException $diagnostics $_
                }
                Assert-Diagnostics $diagnostics
            }
        }
        
        if ($null -ne $script.output -AND -not $dryRun) {
            $variables = @{ config=$config; params=$params; actions=$actions }
            $allOutput = ConvertFrom-ParameterizedAnything -script $script.output -variables $variables -diagnostics $diagnostics
            $allOutput.result | Write-Output
        }
    } catch {
        Assert-Diagnostics $diagnostics
        throw
    }
}

Export-ModuleMember -Function Invoke-Script
