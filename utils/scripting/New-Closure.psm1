function New-Closure(
    [scriptblock] $sourceScript,
    [hashtable] $variables
) {
    # The nested function allows us to control what variables are in scope very
    # carefully; even $sourceScript and $variables will not be in scope here
    function Nested() {
        foreach ($key in $variables.Keys) {
            Set-Variable -Name $key -Value $variables[$key]
        }
        return $sourceScript.GetNewClosure()
    }
    return Nested
}

Export-ModuleMember -Function New-Closure
