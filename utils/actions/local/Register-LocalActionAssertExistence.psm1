Import-Module -Scope Local "$PSScriptRoot/../../core.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../../query-state.psm1"

function Register-LocalActionAssertExistence([PSObject] $localActions) {
    $localActions['assert-existence'] = ${function:Invoke-AssertBranchExistenceLocalAction}
}

function Invoke-AssertBranchExistenceLocalAction {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()] $branches,
        [Parameter(Mandatory)][bool] $shouldExist,
        [Parameter()][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics
    )

    $remote = $(Get-Configuration).remote
    
    foreach ($branch in $branches) {
        $actualBranch = ($remote) ? "$remote/$branch" : $branch
        Invoke-ProcessLogs "git rev-parse --verify $actualBranch" {
            git rev-parse --verify $actualBranch
        }
        if ($global:LASTEXITCODE -ne 0 -AND $shouldExist) {
            Add-ErrorDiagnostic $diagnostics "Branch $branch did not exist$($remote ? " on remote $remote" : '')."
        } elseif ($global:LASTEXITCODE -eq 0 -AND -not $shouldExist) {
            Add-ErrorDiagnostic $diagnostics "Branch $branch already exists$($remote ? " on remote $remote" : '')."
        }
    }

    return @{}
}

Export-ModuleMember -Function Register-LocalActionAssertExistence
