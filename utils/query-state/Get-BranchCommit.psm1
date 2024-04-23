Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"

function Get-BranchCommit(
    [Parameter()][string] $branch,
    [Parameter()][hashtable] $commitMappingOverride = @{}
) {
    if ($commitMappingOverride[$branch]) {
        return $commitMappingOverride[$branch]
    }
    $result = Invoke-ProcessLogs "git rev-parse --verify $branch" {
        git rev-parse --verify $branch
    } -allowSuccessOutput
    if ($global:LASTEXITCODE -ne 0) { return $null }
    return $result
}

Export-ModuleMember -Function Get-BranchCommit
