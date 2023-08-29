
function Expand-StringArray {
    [OutputType([System.Collections.Generic.List[string]])]
    Param (
        [Parameter()][string[]]$strings
    )

    if ($strings -eq $nil) {
        return ,@();
    }
    return ,($strings | ForEach-Object { $_.split(',') } | ForEach-Object { $_ })
}

Export-ModuleMember -Function Expand-StringArray
