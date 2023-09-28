
# Already migrated to ConvertTo-HashMap
filter ArrayToHash([ScriptBlock]$getKey, [ScriptBlock]$getValue)
{
    begin { $hash = @{} }
    process {
        $key = ($getKey -ne $nil) ? (& $getKey $_) : $_
        $value = ($getValue -ne $nil) ? (& $getValue $_) : $_
        $hash[[String]$key] = $value
    }
    end { return $hash }
}
