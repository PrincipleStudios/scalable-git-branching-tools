Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../scripting/ConvertFrom-ParameterizedAnything.psm1"
Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.internal.psm1"

function New-SafeScript([string] $header, [string[]] $script) {
    return [ScriptBlock]::Create("
        $header
        Set-StrictMode -Version 3.0; 
        try {
            $($script -join "`n")
        } catch {
        }
    ")
}

function Register-LocalActionRecurse([PSObject] $localActions) {
    $localActions['recurse'] = ${function:Invoke-RecursiveScript}
}

function Invoke-RecursiveScript {
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
        $recursionContext = @{}

        $instructions = Get-Content "$PSScriptRoot/../../../$path" | ConvertFrom-Json
        $depthFirst = $instructions.recursion.mode -eq 'depth-first'

        $addDepthParam = ($inputParameters | Where-Object { $null -ne $_.depth }).Count -eq 0
        if ($addDepthParam) {
            $inputParameters = @($inputParameters | ForEach-Object { (ConvertTo-Hashtable $_) + @{ depth = 0 } })
        }
        [System.Collections.ArrayList]$allInputs = @() + $inputParameters
        [System.Collections.ArrayList]$inputStack = @() + $inputParameters
        [System.Collections.ArrayList]$pendingAct = @()

        $init = New-SafeScript -header 'param($recursionContext)' `
            -script ($instructions.recursion.init ?? '$null')
        $paramScript = New-SafeScript -header 'param($actions, $params, $previous, $recursionContext)' `
            -script $instructions.recursion.paramScript 
        $canActScript = New-SafeScript -header 'param($actions, $params, $recursionContext)' `
            -script ($instructions.recursion.actCondition ?? '$true')
        $mapScript = New-SafeScript -header 'param($actions, $params, $recursionContext)' `
            -script ($instructions.recursion.map ?? '$null')
        $reduceToOutput = New-SafeScript -header 'param($mapped, $recursionContext)' `
            -script ($instructions.recursion.reduceToOutput ?? '$null')

        (& $init -recursionContext $recursionContext) > $null

        # depth first with a stack requires an extra check to revisit the item
        # an extra time. This hashmap allows an object as the key and tracks
        # which parameters are in the stack a second time, meaning their
        # children have already been processed.
        $depthFirstComplete = @{}

        while ($inputStack.Count -gt 0) {
            $params = $inputStack[0];
            $inputStack.RemoveAt(0);
            $actions = @{}
            $inputs = @{
                params = $params;
                actions = $actions;
                recursionContext = $recursionContext;
            }
            if ($depthFirst -AND $depthFirstComplete[$params]) {
                $pendingAct.Add($params) > $null
                continue
            }
            $inputs.actions = Invoke-Prepare -prepareScripts $instructions.prepare @inputs @commonParams
            [array]$newParams = (& $paramScript -actions $inputs.actions -params $inputs.params -previous $allInputs -recursionContext $recursionContext)
            if ($addDepthParam -AND $null -ne $newParams) {
                [array]$newParams = $newParams | ForEach-Object { (ConvertTo-Hashtable $_) + @{ depth = $params.depth + 1 } }
            }
            $canAct = (& $canActScript -actions $inputs.actions -params $inputs.params -recursionContext $recursionContext)
            if ($depthFirst) {
                if ($canAct) {
                    $inputStack.Insert(0, $inputs) > $null
                    $depthFirstComplete[$inputs] = $true
                }
                if ($null -ne $newParams) {
                    [array]$newParams = @() + [array]$newParams
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
        while ($pendingAct.Count -gt 0) {
            $inputs = $pendingAct[0]
            $pendingAct.RemoveAt(0);
            $inputs.actions = Invoke-Act -actScripts $instructions.act @inputs @commonParams
            $mapResult = & $mapScript -actions $inputs.actions -params $inputs.params -recursionContext $recursionContext
            $mapped.Add($mapResult) > $null
            if (Get-HasErrorDiagnostic $diagnostics) {
                return $null
            }
        }

        return & $reduceToOutput -mapped $mapped -recursionContext $recursionContext
}

function Invoke-Prepare(
    $config,
    $prepareScripts,
    $params,
    $actions,
    $recursionContext,

    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    
    for ($i = 0; $i -lt $prepareScripts.Count; $i++) {
        $name = $prepareScripts[$i].id ?? "#$($i + 1) (1-based)";
        $variables = @{ config=$config; params=$params; actions=$actions; recursionContext=$recursionContext }
        if ($prepareScripts[$i].condition) {
            $condition = ConvertFrom-ParameterizedAnything -script $prepareScripts[$i].condition -variables $variables -diagnostics $diagnostics
            if (-not $condition.fail -AND -not $condition.result) {
                continue;
            }
        }
        $local = ConvertFrom-ParameterizedAnything -script $prepareScripts[$i] -variables $variables -diagnostics $diagnostics
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
    $recursionContext,

    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
) {
    
    for ($i = 0; $i -lt $actScripts.Count; $i++) {
        $name = $actScripts[$i].id ?? "#$($i + 1) (1-based)";
        $variables = @{ config=$config; params=$params; actions=$actions; recursionContext=$recursionContext }
        if ($actScripts[$i].condition) {
            $condition = ConvertFrom-ParameterizedAnything -script $actScripts[$i].condition -variables $variables -diagnostics $diagnostics
            if (-not $condition.fail -AND -not $condition.result) {
                continue;
            }
        }
        $local = ConvertFrom-ParameterizedAnything -script $actScripts[$i] -variables $variables -diagnostics $diagnostics
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
