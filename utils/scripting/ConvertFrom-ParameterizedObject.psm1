Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"

function ConvertFrom-ParameterizedObject(
    [Parameter(Mandatory)][PSObject] $script,
    [Parameter(Mandatory)][PSObject] $config,
    [Parameter(Mandatory)][PSObject] $params,
    [Parameter(Mandatory)][PSObject] $actions,
    [Parameter(Mandatory)][scriptblock] $convertFromParameterized,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failOnError
) {
    $fail = $false

    $ht = ConvertTo-Hashtable $script

    $converted = $ht.Keys | ConvertTo-HashMap -getValue {
        $target = $ht[$_]
        $entry = & $convertFromParameterized -script $target -config $config -params $params -actions $actions -diagnostics $diagnostics -failOnError:$failOnError
        $fail = $fail -or $entry.fail
        return $entry.result
    } -getKey {
        $entry = ConvertFrom-ParameterizedString -script $_ -config $config -params $params -actions $actions -diagnostics $diagnostics -failOnError:$failOnError
        $fail = $fail -or $entry.fail
        return $entry.result
    }

    return @{ result = $converted; fail = $fail }
}

Export-ModuleMember -Function ConvertFrom-ParameterizedObject
