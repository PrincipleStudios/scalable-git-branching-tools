Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionGetDownstream([PSObject] $localActions) {
    $localActions['get-downstream'] = {
        param(
            [Parameter(Mandatory)][string] $target,
            [Parameter()][AllowNull()] $overrideUpstreams,
            [switch] $recurse,
            [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
        )

        [string[]]$result = Select-DownstreamBranches -branchName $target -recurse:$recurse -overrideUpstreams:$overrideUpstreams

        return $result
    }
}

Export-ModuleMember -Function Register-LocalActionGetDownstream
