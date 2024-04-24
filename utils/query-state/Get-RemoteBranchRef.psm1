Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/Configuration.psm1"

# TODO: use the remote's refspec
function Get-RemoteBranchRef(
    [Parameter()][string] $branch,
    [Parameter()][hashtable][AllowNull()] $configuration
) {
    $configuration = $configuration ?? (Get-Configuration)
    $remote = $configuration.remote
    return ($remote) ? "$remote/$branch" : $branch
}

Export-ModuleMember -Function Get-RemoteBranchRef
