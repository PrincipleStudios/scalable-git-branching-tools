$SessionStateProperty = [ScriptBlock].GetProperty('SessionState',([System.Reflection.BindingFlags]'NonPublic,Instance'))

function Invoke-WithUnderscore(
    [Parameter(Position=0)][ScriptBlock]$target,
    [Parameter(Position=1)]$value
) {
    # adapted from https://stackoverflow.com/q/35897998/195653, which is reportedly how the LINQ module handles Invoke-ScriptBlock
    $SessionState = $SessionStateProperty.GetValue($target, $null)
    $OldUnderscore = $SessionState.PSVariable.GetValue('_')
    try {
        $SessionState.PSVariable.Set('_', $value) *>$nil
        return $SessionState.InvokeCommand.InvokeScript($SessionState, $target, @())
    }
    finally {
        $SessionState.PSVariable.Set('_', $OldUnderscore)
    }
}

function ConvertTo-HashMap(
    [Parameter(Position=0)][ScriptBlock]$getKey,
    [Parameter(Position=1)][ScriptBlock]$getValue,
    [Parameter(Mandatory, ValueFromPipeline = $true)]$input
)
{
    begin {
        $hash = @{}
    }
    process {
        $current = $_
        $key = ($getKey -ne $nil) ? (Invoke-WithUnderscore $getKey $current) : $current
        $value = ($getValue -ne $nil) ? (Invoke-WithUnderscore $getValue $current) : $current
        $hash[[String]$key] = $value
    }
    end { return $hash }
}

Export-ModuleMember -Function ConvertTo-HashMap
