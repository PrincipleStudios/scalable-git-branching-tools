Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/New-Closure.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedString.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedArray.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedObject.psm1"


<#
.SYNOPSIS
    expected already-deserialized JSON content, using PSOjbect, arrays, and strings
#>
function ConvertFrom-ParameterizedAnything(
    [Parameter(Mandatory)][AllowNull()][PSCustomObject] $script,
    [Parameter(Mandatory)][PSObject] $variables,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failOnError
) {
    if ($null -eq $script) {
        return @{ result = $null; fail = $false }
    } elseif ($script -is [bool]) {
        return @{ result = $script; fail = $false }
    } elseif ($script -is [string] -AND $script[0] -eq '$' -AND $script[1] -ne '(') {
        try {
            $targetScript = New-Closure ([ScriptBlock]::Create('
                Set-StrictMode -Version 3.0; 
                try {
                    @{ result = ' + $script.replace('`', '``').replace('{', '`{').replace('}', '`}').replace(';', '`;') + '; fail = $false }
                } catch {
                    $null
                }
            ')) -variables $variables
            $entry = Invoke-Command -ScriptBlock $targetScript
        } catch {
            $entry = $null
        }
        if ($null -ne $entry) {
            return $entry
        } else {
            Add-ErrorDiagnostic $diagnostics "Error trying to handle script '$script'; please ensure strings use `$(...) syntax"
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
