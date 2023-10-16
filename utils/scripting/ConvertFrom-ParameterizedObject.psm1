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

    $converted = @{}
    foreach ($_ in $ht.Keys) {
        $entry = & $convertFromParameterized -script $_ -config $config -params $params -actions $actions -diagnostics $diagnostics -failOnError:$failOnError
        if ($entry.result -isnot [string]) {
            $fail = $true
            continue
        }
        $fail = $fail -or $entry.fail

        $target = $ht[$_]
        $entryValue = & $convertFromParameterized -script $target -config $config -params $params -actions $actions -diagnostics $diagnostics -failOnError:$failOnError
        $fail = $fail -or $entryValue.fail
        
        $converted += @{ $entry.result = $entryValue.result }
    }

    return @{ result = $converted; fail = $fail }
}

Export-ModuleMember -Function ConvertFrom-ParameterizedObject
