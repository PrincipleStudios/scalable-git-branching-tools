Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedScript.psm1"

function ConvertFrom-ParameterizedObject(
    [PSCustomObject] $scripts,
    [PSObject] $params,
    [PSObject] $actions, 
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failIfUnableToParse
) {
    $fail = $false
    $converted = $scripts.Keys | ConvertTo-HashMap -getValue {
        $target = $scripts[$_]
        $entry = ConvertFrom-ParameterizedScript -script $target -params $params -actions $actions
        if ($null -eq $entry) {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is used outside the convert script')]
            $fail = $true
            if ($failIfUnableToParse) {
                Add-ErrorDiagnostic $diagnostics "Unable to evaluate script: '$target'"
            } elseif ($null -ne $diagnostics) {
                Add-WarningDiagnostic $diagnostics "Unable to evaluate script: '$target'"
            }
        }
        return $entry
    } -getKey {
        $entry = ConvertFrom-ParameterizedScript -script $_ -params $params -actions $actions
        if ($null -eq $entry) {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is used outside the convert script')]
            $fail = $true
            if ($failIfUnableToParse) {
                Add-ErrorDiagnostic $diagnostics "Unable to evaluate script: '$_'"
            } elseif ($null -ne $diagnostics) {
                Add-WarningDiagnostic $diagnostics "Unable to evaluate script: '$_'"
            }
        }
        return $entry
    }

    if ($fail) { return $null }
    return $converted
}

Export-ModuleMember -Function ConvertFrom-ParameterizedObject
