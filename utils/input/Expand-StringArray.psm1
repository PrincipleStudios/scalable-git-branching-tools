
function Expand-StringArray {
    [OutputType([System.Collections.Generic.List[string]])]
    Param (
        [Parameter()][string[]]$strings
    )

    if ($strings -eq $nil) {
        # Powershell unwraps the empty list to $nil unless we do this
        return ,@();
    }
    return ,($strings | ForEach-Object { $_.split(',') } | ForEach-Object { $_ })
}

Export-ModuleMember -Function Expand-StringArray
