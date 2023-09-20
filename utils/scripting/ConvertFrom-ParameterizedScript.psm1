
function ConvertFrom-ParameterizedScript([string] $script, [PSObject] $params, [PSObject] $actions) {
    $targetScript = [ScriptBlock]::Create('
    Set-StrictMode -Version 3.0; 
    try {
        "' + $script.replace('`', '``').replace('"', '`"') + '"
    } catch {
        $null
    }
    ')
    return Invoke-Command -ScriptBlock $targetScript
}

Export-ModuleMember -Function ConvertFrom-ParameterizedScript
