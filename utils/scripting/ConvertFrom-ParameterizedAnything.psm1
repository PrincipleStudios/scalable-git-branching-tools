Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedArray.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedObject.psm1"


<#
.SYNOPSIS
    expected already-deserialized JSON content, using PSOjbect, arrays, and strings
#>
function ConvertFrom-ParameterizedAnything(
    [Parameter(Mandatory)][AllowNull()][PSCustomObject] $script,
    [Parameter(Mandatory)][PSObject] $params,
    [Parameter(Mandatory)][PSObject] $actions,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failOnError
) {
    if ($null -eq $script) {
        return @{ result = $null; fail = $false }
    } elseif ($script -is [string]) {
        return ConvertFrom-ParameterizedString @PSBoundParameters
    } elseif ($script -is [array]) {
        $result = ConvertFrom-ParameterizedArray @PSBoundParameters -convertFromParameterized ${function:ConvertFrom-ParameterizedAnything}
        return $result
    } elseif ($script -is [PSObject] -or $script -is [PSCustomObject] -or $script -is [Hashtable]) {
        $result = ConvertFrom-ParameterizedObject @PSBoundParameters -convertFromParameterized ${function:ConvertFrom-ParameterizedAnything}
        return $result
    } else {
        Add-ErrorDiagnostic $diagnostics "Unknown type $($script.GetType().FullName) when parameterizing"
        return @{ result = $null; fail = $true }
    }
}

Export-ModuleMember -Function ConvertFrom-ParameterizedAnything
