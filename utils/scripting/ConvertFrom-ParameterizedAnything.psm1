Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedArray.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedObject.psm1"


<#
.SYNOPSIS
    expected already-deserialized JSON content, using PSOjbect, arrays, and strings
#>
function ConvertFrom-ParameterizedAnything(
    [Parameter(Mandatory)][AllowNull()][PSCustomObject] $script,
    [Parameter(Mandatory)][PSObject] $config,
    [Parameter(Mandatory)][PSObject] $params,
    [Parameter(Mandatory)][PSObject] $actions,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failOnError
) {
    if ($null -eq $script) {
        return @{ result = $null; fail = $false }
    } elseif ($script -is [string] -AND $script[0] -eq '$' -AND $script[1] -ne '(') {
        try {
            $targetScript = [ScriptBlock]::Create('
                Set-StrictMode -Version 3.0; 
                try {
                    ' + $script.replace('`', '``').replace('{', '`{').replace('}', '`}') + '
                } catch {
                    $null
                }
            ')
            $entry = Invoke-Command -ScriptBlock $targetScript
        } catch {
            $entry = $null
        }
        if ($null -ne $entry) {
            return @{ result = $entry; fail = $false }
        } else {
            Add-ErrorDiagnostic $diagnostics "Error trying to handle script '$_'; please ensure strings use `$(...) syntax"
            return @{ result = $null; fail = $true }
        }
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
