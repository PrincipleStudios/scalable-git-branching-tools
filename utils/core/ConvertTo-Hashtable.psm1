
function ConvertTo-Hashtable(
    [Parameter(Mandatory)] $value
) {
    if ($value -is [Hashtable]) {
        return $value
    } else {
        $ht = @{}
        $props = $value.Properties ?? $value.PSObject.Properties
        $props | ForEach-Object { $ht[$_.Name] = $_.Value }

        return $ht
    }
}

Export-ModuleMember -Function ConvertTo-Hashtable
