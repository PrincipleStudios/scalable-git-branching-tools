
function Should-BeObject {
    Param (
        [Parameter(Position=0)][Object]$b, [Parameter(ValueFromPipeLine = $True)][Object]$a
    )

    if ($a -eq $nil -AND $b -eq $nil) {
        return;
    } elseif ($a -eq $nil -OR $b -eq $nil) {
        throw 'One, but not both, arguments were null.'
    }
    
    $Property = (($a.PSObject.Properties | Select-Object -Expand Name) + ($b.PSObject.Properties | Select-Object -Expand Name)) | select -uniq
    $Difference = Compare-Object $b $a -Property $Property
    if ($Difference.Length -ne 0) {
        throw "Expected objects to be the same, but got difference: $($a | ConvertTo-Json) expected to match $($b | ConvertTo-Json)"
    }
}
