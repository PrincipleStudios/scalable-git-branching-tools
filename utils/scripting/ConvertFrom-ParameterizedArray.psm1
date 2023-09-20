Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../input.psm1"
Import-Module -Scope Local "$PSScriptRoot/ConvertFrom-ParameterizedScript.psm1"

function ConvertFrom-ParameterizedArray(
    [string[]] $scripts,
    [PSObject] $params,
    [PSObject] $actions, 
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failIfUnableToParse
) {
    
    $converted = $scripts | ForEach-Object {
        $entry = ConvertFrom-ParameterizedScript -script $_ -params $params -actions $actions
        if ($null -eq $entry) {
            if ($failIfUnableToParse) {
                Add-ErrorDiagnostic $diagnostics "Unable to evaluate script: '$_'"
            } elseif ($null -ne $diagnostics) {
                Add-WarningDiagnostic $diagnostics "Unable to evaluate script: '$_'"
            }
        }
        return $entry
    }
    if ($converted -contains $null) { return $null }
    return Expand-StringArray $converted
}

Export-ModuleMember -Function ConvertFrom-ParameterizedArray
