Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"

function ConvertFrom-ParameterizedArray(
    [Parameter(Mandatory)][object[]] $script,
    [Parameter(Mandatory)][PSObject] $variables,
    [Parameter(Mandatory)][scriptblock] $convertFromParameterized,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failOnError
) {
    $fail = $false
    $converted = New-Object -TypeName 'System.Collections.ArrayList'
    foreach ($_ in $script) {
        if ($null -eq $_) {
            $converted.Add($null) *> $null
        } else {
            $entry = & $convertFromParameterized -script $_ -variables $variables -diagnostics $diagnostics -failOnError:$failOnError
            $fail = $fail -or $entry.fail
            if ($entry.result -is [array]) {
                foreach ($item in $entry.result) {
                    $converted.Add($item) *> $null
                }
            } elseif ($entry.result -is [string]) {
                $expanded = Expand-StringArray $entry.result
                foreach ($item in $expanded) {
                    $converted.Add($item) *> $null
                }
            } else {
                $converted.Add($entry.result) *> $null
            }
        }
    }
    return @{ result = $converted; fail = $fail }
}

Export-ModuleMember -Function ConvertFrom-ParameterizedArray
