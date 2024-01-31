Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../scripting/ConvertFrom-ParameterizedAnything.psm1"
Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.internal.psm1"

function New-SafeScript([string] $header, [string] $script) {
    return [ScriptBlock]::Create("
        $header
        Set-StrictMode -Version 3.0; 
        try {
            $script
        } catch {
        }
    ")
}

function Register-LocalActionRecurse([PSObject] $localActions) {
    $localActions['recurse'] = {
        param(
            [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $inputParameters,
            [Parameter(Mandatory)][string] $path,
            
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        $config = Get-Configuration
        $commonParams = @{
            config = $config
            diagnostics = $diagnostics
        }

        $instructions = Get-Content "$PSScriptRoot/../../../$path" | ConvertFrom-Json
        $depthFirst = $instructions.recursion.mode -eq 'depth-first'

        $addDepthParam = ($inputParameters | Where-Object { $null -ne $_.depth }).Count -eq 0
        if ($addDepthParam) {
            $inputParameters = @($inputParameters | ForEach-Object { (ConvertTo-Hashtable $_) + @{ depth = 0 } })
        }
        [System.Collections.ArrayList]$allInputs = @() + $inputParameters
        [System.Collections.ArrayList]$inputStack = @() + $inputParameters
        [System.Collections.ArrayList]$pendingAct = @()

        $paramScript = New-SafeScript -header 'param($actions, $params, $previous)' `
            -script $instructions.recursion.paramScript 
        $canActScript = New-SafeScript -header 'param($actions, $params)' `
            -script ($instructions.recursion.actCondition ?? '$true')
        $mapScript = New-SafeScript -header 'param($actions, $params)' `
            -script $instructions.recursion.map
        $reduceToOutput = New-SafeScript -header 'param($mapped)' `
            -script $instructions.recursion.reduceToOutput

        while ($inputStack.Count -gt 0) {
            $params = $inputStack[0];
            $inputStack.RemoveAt(0);
            $actions = @{}
            $inputs = @{
                params = $params;
                actions = $actions;
            }
            $inputs.actions = Invoke-Prepare -prepareScripts $instructions.prepare @inputs @commonParams
            [array]$newParams = (& $paramScript -actions $inputs.actions -params $inputs.params -previous $allInputs)
            if ($addDepthParam -AND $null -ne $newParams) {
                [array]$newParams = $newParams | ForEach-Object { (ConvertTo-Hashtable $_) + @{ depth = $params.depth + 1 } }
            }
            $canAct = (& $canActScript -actions $inputs.actions -params $inputs.params)
            if ($depthFirst) {
                if ($canAct) {
                    $pendingAct.Insert(0, $inputs)
                }
                if ($null -ne $newParams) {
                    $inputStack.InsertRange(0, $newParams)
                }
            } else {
                if ($canAct) {
                    $pendingAct.Add($inputs) > $null
                }
                if ($null -ne $newParams) {
                    $inputStack.AddRange($newParams)
                }
            }
            if ($null -ne $newParams) {
                $allInputs += $newParams
            }
            if (Get-HasErrorDiagnostic $diagnostics) {
                return $null
            }
        }

        [System.Collections.ArrayList]$mapped = @()
        if ($depthFirst) {
            $pendingAct.Reverse()
        }
        while ($pendingAct.Count -gt 0) {
            $inputs = $pendingAct[0]
            $pendingAct.RemoveAt(0);
            $inputs.actions = Invoke-Act -actScripts $instructions.act @inputs @commonParams
            $mapResult = & $mapScript -actions $inputs.actions -params $inputs.params
            $mapped.Add($mapResult) > $null
            if (Get-HasErrorDiagnostic $diagnostics) {
                return $null
            }
        }

        return & $reduceToOutput -mapped $mapped
    }
}

function Invoke-Prepare(
    $config,
    $prepareScripts,
    $params,
    $actions,

    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    
    for ($i = 0; $i -lt $prepareScripts.Count; $i++) {
        $name = $prepareScripts[$i].id ?? "#$($i + 1) (1-based)";
        $local = ConvertFrom-ParameterizedAnything -script $prepareScripts[$i] -config $config -params $params -actions $actions -diagnostics $diagnostics
        if ($local.fail) {
            Add-ErrorDiagnostic $diagnostics "Could not apply parameters to recursive prepare (local) action $name; see above errors. Evaluation below:"
            Add-ErrorDiagnostic $diagnostics "$(ConvertTo-Json $local.result -Depth 10)"
            break
        }
        try {
            $outputs = Invoke-LocalAction $local.result -diagnostics $diagnostics
            if ($null -ne $local.result.id) {
                $actions += @{ $local.result.id = @{ outputs = $outputs } }
            }
        } catch {
            Add-ErrorDiagnostic $diagnostics "Encountered error while running recursive prepare (local) action $($name), evaluated below, with the error following."
            Add-ErrorDiagnostic $diagnostics "$(ConvertTo-Json $local.result -Depth 10)"
            Add-ErrorException $diagnostics $_
        }
        if (Get-HasErrorDiagnostic $diagnostics) {
            return $actions
        }
    }

    return $actions
}

function Invoke-Act(
    $config,
    $actScripts,
    $params,
    $actions,

    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    
    for ($i = 0; $i -lt $actScripts.Count; $i++) {
        $name = $actScripts[$i].id ?? "#$($i + 1) (1-based)";
        $local = ConvertFrom-ParameterizedAnything -script $actScripts[$i] -config $config -params $params -actions $actions -diagnostics $diagnostics
        if ($local.fail) {
            Add-ErrorDiagnostic $diagnostics "Could not apply parameters to recursive act (local) action $name; see above errors. Evaluation below:"
            Add-ErrorDiagnostic $diagnostics "$(ConvertTo-Json $local.result -Depth 10)"
            break
        }
        try {
            $outputs = Invoke-LocalAction $local.result -diagnostics $diagnostics
            if ($null -ne $local.result.id) {
                $actions += @{ $local.result.id = @{ outputs = $outputs } }
            }
        } catch {
            Add-ErrorDiagnostic $diagnostics "Encountered error while running recursive act (local) action $($name), evaluated below, with the error following."
            Add-ErrorDiagnostic $diagnostics "$(ConvertTo-Json $local.result -Depth 10)"
            Add-ErrorException $diagnostics $_
        }
        if (Get-HasErrorDiagnostic $diagnostics) {
            return $actions
        }
    }

    return $actions
}

Export-ModuleMember -Function Register-LocalActionRecurse