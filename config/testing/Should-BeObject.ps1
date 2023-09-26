# Already migrated to Assert-ShouldBeObject
function Should-BeObject {
    Param (
        [Parameter(Position=0)][PSObject]$b, [Parameter(ValueFromPipeLine = $True)][PSObject]$a
    )

    if ($a -eq $nil -AND $b -eq $nil) {
        return;
    } elseif ($a -eq $nil) {
        throw 'Expected a value but got null.'
    } elseif ($b -eq $nil) {
        throw 'Expected null but got a value.'
    }

    $aType = $a.GetType().FullName
    $bType = $b.GetType().FullName
    if ($aType -ne $bType) {
        throw "Expected objects to be the same type, expected $aType but got $bType."
    }

    if ($aType -eq 'System.Collections.Hashtable') {
        $Property = @(($a.Keys), ($b.Keys)) | ForEach-Object {$_} | select -uniq
    } else {
        $Property = @(($a.PSObject.Properties | Select-Object -Expand Name), ($b.PSObject.Properties | Select-Object -Expand Name)) | ForEach-Object {$_} | select -uniq
            | Where-Object { @('Keys', 'Values') -notcontains $_ }
    }
    $Property | ForEach-Object {
        $prop = $_
        try {
            $a[$_] | Should -Be $b[$_]
        } catch {
            throw "Expected objects to be the same for property '$prop': $_"
        }
    }
}
