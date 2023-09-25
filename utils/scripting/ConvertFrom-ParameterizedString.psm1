Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

function ConvertFrom-ParameterizedString(
    [string] $script, 
    [PSObject] $params,
    [PSObject] $actions,
    [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $failOnError
) {
    $targetScript = [ScriptBlock]::Create('
    Set-StrictMode -Version 3.0; 
    try {
        "' + $script.replace('`', '``').replace('"', '`"') + '"
    } catch {
        $null
    }
    ')
    $entry = Invoke-Command -ScriptBlock $targetScript
    if ($null -eq $entry) {
        if ($failOnError) {
            Add-ErrorDiagnostic $diagnostics "Unable to evaluate script: '$script'"
        } elseif ($null -ne $diagnostics) {
            Add-WarningDiagnostic $diagnostics "Unable to evaluate script: '$script'"
        }
    }
    return @{ result = $entry; fail = $null -eq $entry }
}

Export-ModuleMember -Function ConvertFrom-ParameterizedString
