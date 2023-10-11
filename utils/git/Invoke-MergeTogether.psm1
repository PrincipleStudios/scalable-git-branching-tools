Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"

function Invoke-MergeTogether(
    [Parameter(Mandatory)][String[]] $commitishes, 
    [Parameter()][string] $messageTemplate = "Merge {}",
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $asWarnings
) {

    [String[]]$remaining = $commitishes
    [String[]]$failed = @()
    [String[]]$successful = @()

    $currentCommit = $null
    while ($remaining.Count -gt 0) {
        $target = $remaining[0]
        if ($null -eq $currentCommit) {
            $parsedCommitish = Invoke-ProcessLogs "git rev-parse --verify $target" {
                git rev-parse --verify $target
            } -allowSuccessOutput
            if ($global:LASTEXITCODE -eq 0) {
                $currentCommit = $parsedCommitish
                $remaining = $remaining | Where-Object { $_ -ne $target }
                $successful += $target
            } else {
                $remaining = $remaining | Where-Object { $_ -ne $target }
                $failed += $target
                if ($asWarnings) {
                    Add-WarningDiagnostic $diagnostics "Could not resolve '$($target)'"
                } else {
                    Add-ErrorDiagnostic $diagnostics "Could not resolve '$($target)'"
                }
            }
        } else {
            $allFailed = $true
            for ($i = 0; $i -lt $remaining.Count; $i++) {
                $target = $remaining[$i]
                $mergeTreeResult = Get-MergeTree $currentCommit $target
                if (-not $mergeTreeResult.isSuccess) { continue }
                $nextTree = $mergeTreeResult.treeish

                $commitMessage = $messageTemplate.Replace('{}', $target)
                $resultCommit = Invoke-ProcessLogs "git commit-tree $nextTree -m $commitMessage -p $currentCommit" {
                    git commit-tree $nextTree -m $commitMessage -p $currentCommit
                } -allowSuccessOutput
                if ($global:LASTEXITCODE -ne 0) { continue }

                $currentCommit = $resultCommit
                $allFailed = $false
                $i--
                $remaining = $remaining | Where-Object { $_ -ne $target }
                $successful += $target
                break;
            }
            if ($allFailed) {
                if ($asWarnings) {
                    Add-WarningDiagnostic $diagnostics "Could not merge the following branches: $remaining"
                } else {
                    Add-ErrorDiagnostic $diagnostics "Could not merge the following branches: $remaining"
                }

                $failed += $remaining
                $remaining = @()
            }
        }
    }

    return @{
        result = $currentCommit
        successful = $successful
        failed = $failed
    }
}

Export-ModuleMember -Function Invoke-MergeTogether
