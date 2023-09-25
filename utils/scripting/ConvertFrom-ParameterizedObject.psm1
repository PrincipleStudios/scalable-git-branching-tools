Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"

function ConvertFrom-ParameterizedObject(
    [Parameter(Mandatory)][PSObject] $script,
    [Parameter(Mandatory)][PSObject] $params,
    [Parameter(Mandatory)][PSObject] $actions,
    [Parameter(Mandatory)][scriptblock] $convertFromParameterized,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failOnError
) {
    $fail = $false

    if ($script -is [Hashtable]) {
        $ht = $script
    } else {
        $ht = @{}
        $props = $script.Properties ?? $script.PSObject.Properties
        $props | ForEach-Object { $ht[$_.Name] = $_.Value }
    }

    $converted = $ht.Keys | ConvertTo-HashMap -getValue {
        $target = $ht[$_]
        $entry = & $convertFromParameterized -script $target -params $params -actions $actions -diagnostics $diagnostics -failOnError:$failOnError
        $fail = $fail -or $entry.fail
        return $entry.result
    } -getKey {
        $entry = ConvertFrom-ParameterizedString -script $_ -params $params -actions $actions -diagnostics $diagnostics -failOnError:$failOnError
        $fail = $fail -or $entry.fail
        return $entry.result
    }

    return @{ result = $converted; fail = $fail }
}

Export-ModuleMember -Function ConvertFrom-ParameterizedObject
