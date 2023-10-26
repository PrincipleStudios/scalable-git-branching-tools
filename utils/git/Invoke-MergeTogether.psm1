Import-Module -Scope Local "$PSScriptRoot/../framework.psm1"
Import-Module -Scope Local "$PSScriptRoot/../query-state.psm1"

function Invoke-MergeTogether(
    [Parameter(Mandatory)][String[]] $commitishes, 
    [Parameter()][AllowNull()][string] $source = $null,
    [Parameter()][string] $messageTemplate = "Merge {}",
    [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList] $diagnostics,
    [switch] $asWarnings
) {

    [String[]]$remaining = $commitishes
    [String[]]$failed = @()
    [String[]]$successful = @()

    $currentCommit = $null
    if ($null -ne $source -AND '' -ne $source) {
        $target = $source

        $currentCommit = Invoke-ProcessLogs "git rev-parse --verify $target" {
            git rev-parse --verify $target
        } -allowSuccessOutput
        if ($global:LASTEXITCODE -ne 0) {
            $remaining = $remaining | Where-Object { $_ -ne $target }
            $failed += $target
            Add-ErrorDiagnostic $diagnostics "Could not resolve '$($target)' for source of merge"
            
            return @{
                result = $null
                successful = @()
                failed = @($target)
            }
        }
    }
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
                $targetCommit = Invoke-ProcessLogs "git rev-parse --verify $target" {
                    git rev-parse --verify $target
                } -allowSuccessOutput
                if ($global:LASTEXITCODE -ne 0) {
                    # If we can't resolve the commit, it'll never resolve
                    $remaining = $remaining | Where-Object { $_ -ne $target }
                    $failed += $target
                    if ($asWarnings) {
                        Add-WarningDiagnostic $diagnostics "Could not resolve '$($target)'"
                    } else {
                        Add-ErrorDiagnostic $diagnostics "Could not resolve '$($target)'"
                    }
                    $i--
                    continue
                }

                $commitsDiff = Invoke-ProcessLogs "git rev-list --count ^$currentCommit $targetCommit" {
                    # Check to see if there are any new commits in the $currentCommit history from $target's history
                    git ref-list --count "^$currentCommit" $targetCommit
                } -allowSuccessOutput
                if ($commitsDiff -ne 0) {
                    # New commits on $currentCommit; do the merge
                    $mergeTreeResult = Get-MergeTree $currentCommit $targetCommit
                    if (-not $mergeTreeResult.isSuccess) { continue }
                    $nextTree = $mergeTreeResult.treeish

                    # Successful merge
                    $commitMessage = $messageTemplate.Replace('{}', $target)
                    $resultCommit = Invoke-ProcessLogs "git commit-tree $nextTree -m $commitMessage -p $currentCommit -p $targetCommit" {
                        git commit-tree $nextTree -m $commitMessage -p $currentCommit -p $targetCommit
                    } -allowSuccessOutput
                    if ($global:LASTEXITCODE -ne 0) { continue }

                    $currentCommit = $resultCommit
                }
                $allFailed = $false
                $i--
                $remaining = $remaining | Where-Object { $_ -ne $target }
                $successful += $target
                break;
            }
            if ($allFailed -AND $remaining.Count -gt 0) {
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
