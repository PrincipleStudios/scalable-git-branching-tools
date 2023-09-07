Import-Module -Scope Local "$PSScriptRoot/Get-UpstreamBranch.psm1"
Import-Module -Scope Local "$PSScriptRoot/Get-GitFile.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../utils/query-state.psm1"

function Select-UpstreamBranches([String]$branchName, [switch] $includeRemote, [switch] $recurse, [string[]] $exclude) {
    $config = Get-Configuration
    $upstreamBranch = Get-UpstreamBranch
    $parentBranches = [string[]](Get-GitFile $branchName $upstreamBranch)

    $parentBranches = $parentBranches | Where-Object { $exclude -notcontains $_ }

    if ($parentBranches -eq $nil -OR $parentBranches.length -eq 0) {
        return [string[]](@())
    }

    if ($recurse) {
        $currentExclude = [string[]]( @($branchName, $exclude) | ForEach-Object { $_ } )
        $finalParents = [string[]]( $parentBranches | ForEach-Object {
            $newParents = [string[]](Select-UpstreamBranches $_ -recurse -exclude $currentExclude)
            if ($newParents -eq $nil) {
                return @()
            }
            $currentExclude = [string[]]( @($currentExclude, $newParents) | ForEach-Object { $_ } )
            return $newParents
        } | ForEach-Object { $_ } )
        $parentBranches = [string[]]( @( $parentBranches, $finalParents ) | ForEach-Object { $_ } | Where-Object { $_ -ne $nil} )
    }

    if ($includeRemote) {
        return $parentBranches | ForEach-Object { $config.remote -eq $nil ? $_ : "$($config.remote)/$_" }
    } else {
        return $parentBranches
    }
}
Export-ModuleMember -Function Select-UpstreamBranches
