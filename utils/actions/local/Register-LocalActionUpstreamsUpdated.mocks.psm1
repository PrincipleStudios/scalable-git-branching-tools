Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../testing.psm1"
Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionUpstreamsUpdated.psm1"

function Invoke-MockGit([string] $gitCli, [object] $MockWith) {
    return Invoke-MockGitModule -ModuleName 'Register-LocalActionUpstreamsUpdated' @PSBoundParameters
}

function Initialize-LocalActionUpstreamsUpdated(
    [Parameter()][AllowEmptyCollection()][string[]] $upToDate,
    [Parameter()][Hashtable] $outOfDate,
    [switch] $recurse
) {

    $config = Get-Configuration
    $prefix = $config.remote ? "refs/remotes/$($config.remote)" : "refs/heads/"

    $branches = ($upToDate + $outOfDate.Keys) | Where-Object { $_ }
    if ($null -eq $branches) { return }
    foreach ($branch in $branches) {
        $upstreams = Select-UpstreamBranches -branch $branch -recurse:$recurse
        $target = "$prefix/$branch"
        $fullyQualifiedUpstreams = $upstreams | ForEach-Object { "$prefix/$_" }

        if ($upToDate -contains $branch) {
            Invoke-MockGit "for-each-ref --format=%(refname:lstrip=3) %(ahead-behind:$target) $fullyQualifiedUpstreams" `
                -mockWith (($upstreams | ForEach-Object { "$_ 5 0" }))
        } else {
            Invoke-MockGit "for-each-ref --format=%(refname:lstrip=3) %(ahead-behind:$target) $fullyQualifiedUpstreams" `
                -mockWith (($upstreams | ForEach-Object { "$_ 5 $($outOfDate[$branch] -contains $_ ? '1' : '0' )" }))
        }
    }
}

Export-ModuleMember -Function Initialize-LocalActionUpstreamsUpdated
