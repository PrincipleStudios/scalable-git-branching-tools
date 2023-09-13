Import-Module -Scope Local "$PSScriptRoot/../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/Select-UpstreamBranches.psm1"

function Compress-UpstreamBranches([Parameter(Mandatory)][AllowEmptyCollection()][string[]] $originalUpstream) {
    $allUpstream = $originalUpstream | ConvertTo-HashMap -getValue {
        return ([string[]](Select-UpstreamBranches $_ -recurse))
    }
    $resultUpstream = [System.Collections.ArrayList]$originalUpstream
    for ($i = 0; $i -lt $resultUpstream.Count; $i++) {
        $branch = $resultUpstream[$i]
        if (($resultUpstream | Where-Object { $_ -ne $branch -AND $allUpstream[$_] -contains $branch }) -ne $nil) {
            # $branch is in the recursive upstream of at least one other branch
            $resultUpstream.Remove($branch)
            $i--
        }
    }
    return [string[]]$resultUpstream
}

Export-ModuleMember -Function Compress-UpstreamBranches
