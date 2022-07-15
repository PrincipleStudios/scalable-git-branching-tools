
function Coalesce($a, $b) { if ($a -ne '' -AND $a -ne $null) { return $a } else { return $b } }
