Import-Module -Scope Local "$PSScriptRoot/Select-AllUpstreamBranches.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

function Select-DownstreamBranches(
    [String]$branchName,
    [switch] $recurse,
    [string[]] $exclude, 
    [Parameter()][AllowNull()] $overrideUpstreams) {
    $all = Select-AllUpstreamBranches -overrideUpstreams:$overrideUpstreams
    $parentBranches = $all.Keys | Where-Object {
        $exclude -notcontains $_
    } | Where-Object {
        $all[$_] -contains $branchName
    }

    if ($parentBranches -eq $nil -OR $parentBranches.length -eq 0) {
        return [string[]](@())
    }

    if ($recurse) {
        $currentExclude = [string[]]( @($branchName, $exclude) | ForEach-Object { $_ } )
        $finalParents = [string[]]( $parentBranches | ForEach-Object {
            $newParents = [string[]](Select-DownstreamBranches $_ -recurse -exclude $currentExclude)
            if ($newParents -eq $nil) {
                return @()
            }
            $currentExclude = [string[]]( @($currentExclude, $newParents) | ForEach-Object { $_ } )
            return $newParents
        } | ForEach-Object { $_ } )
        $parentBranches = [string[]]( @( $parentBranches, $finalParents ) | ForEach-Object { $_ } | Where-Object { $_ -ne $nil} )
    }
    return $parentBranches
}
Export-ModuleMember -Function Select-DownstreamBranches
