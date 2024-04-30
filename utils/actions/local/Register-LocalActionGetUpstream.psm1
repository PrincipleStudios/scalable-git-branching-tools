Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Invoke-GetUpstreamLocalAction {
    param(
        [Parameter(Mandatory)][string] $target,
        [Parameter()][AllowNull()] $overrideUpstreams,
        [switch] $recurse,
        [switch] $includeRemote,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    [string[]]$result = Select-UpstreamBranches -branchName $target -recurse:$recurse -includeRemote:$includeRemote -overrideUpstreams:$overrideUpstreams
    
    return $result
}

Export-ModuleMember -Function Invoke-GetUpstreamLocalAction
